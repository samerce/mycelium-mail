import Foundation
import CoreData
import MailCore


private let accountCtrl = AccountController.shared
private let dataCtrl = PersistenceController.shared


extension Email {
  
  var uidSet: MCOIndexSet { MCOIndexSet(index: UInt64(uid)) }
  var session: MCOIMAPSession { accountCtrl.sessions[account]! }
  
  // MARK: - INIT
  
  func hydrateWithMessage(_ message: MCOIMAPMessage) {
    uid = Int32(message.uid)
    flags = message.flags
    labels = Set(message.gmailLabels as? [String] ?? [])
    threadId = Int64(message.gmailThreadID)
    size = Int32(message.size)
    originalFlags = message.originalFlags
    customFlags = Set(message.customFlags as? [String] ?? [])
    modSeqValue = Int64(message.modSeqValue)
    html = ""
    trashed = false
    
    let header = message.header!
    receivedDate = header.receivedDate
    sentDate = header.date
    subjectRaw = header.subject ?? ""
    userAgent = header.userAgent
    references = Set(header.references as? [String] ?? [])
    messageId = header.messageID ?? ""
    inReplyTo = Set(header.inReplyTo as? [String] ?? [])
    
    if let _sender = header.sender {
      sender = EmailAddress(address: _sender)
    }
    if let _bcc = header.bcc as? [MCOAddress] {
      bcc = _bcc.map { EmailAddress(address: $0) }
    }
    if let _cc = header.cc as? [MCOAddress] {
      cc = _cc.map { EmailAddress(address: $0) }
    }
    if let _replyTo = header.replyTo as? [MCOAddress] {
      replyTo = _replyTo.map { EmailAddress(address: $0) }
    }
    if let _to = header.to as? [MCOAddress] {
      to = _to.map { EmailAddress(address: $0) }
    }
    from = EmailAddress(address: header.from)
  }
  
  // MARK: - HELPERS
  
  private func runOperation(_ op: MCOIMAPOperation?) async throws {
    guard let op = op
    else { throw PsyError.failedToCreateOperation() }
    
    let _: () = try await withCheckedThrowingContinuation { continuation in
      op.start { error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }
  
  private func runOperation(_ op: MCOSMTPOperation?) async throws {
    guard let op = op
    else { throw PsyError.failedToCreateOperation() }
    
    let _: () = try await withCheckedThrowingContinuation { continuation in
      op.start { error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }
  
  private func sessionForType(_ accountType: AccountType) -> MCOIMAPSession {
    switch accountType {
      case .gmail:
        return GmailSession()
    }
  }
  
}

// MARK: - HTML

extension Email {
  
  func fetchHtml() async throws {
    guard html.isEmpty
    else { return }
    
    let html = try await bodyHtml()
    
    let context = dataCtrl.newTaskContext()
    try await context.perform {
      self.html = html
      try context.save()
    }
  }
  
  private func bodyHtml() async throws -> String {
    guard let fetchMessage = session.fetchParsedMessageOperation(withFolder: DefaultFolder,
                                                                  uid: UInt32(uid))
    else {
      throw PsyError.unexpectedError(message: "failed to create fetch HTML operation")
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      fetchMessage.start() { error, parser in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: parser?.htmlBodyRendering() ?? "")
        }
      }
    }
  }
  
}


// MARK: - FLAGS

extension Email {
  
  var seen: Bool { flags.contains(.seen) }
  var flagged: Bool { flags.contains(.flagged) }
  
  private var flags: MCOMessageFlag {
    get {
      MCOMessageFlag(rawValue: Int(flagsRaw))
    }
    set {
      flagsRaw = Int16(newValue.rawValue)
    }
  }
  
  private(set) var originalFlags: MCOMessageFlag {
    get {
      MCOMessageFlag(rawValue: Int(originalFlagsRaw))
    }
    set {
      originalFlagsRaw = Int16(newValue.rawValue)
    }
  }
  
  func markSeen(_ seen: Bool = true) async throws {
    guard seen != self.seen
    else { return }
    
    try await updateFlags(.seen, operation: seen ? .add : .remove)
  }
  
  func markFlagged(_ flagged: Bool = true) async throws {
    guard flagged != self.flagged
    else { return }
    
    try await updateFlags(.flagged, operation: flagged ? .add : .remove)
  }
  
  func updateFlags(_ flags: MCOMessageFlag, operation: MCOIMAPStoreFlagsRequestKind) async throws {
    print("updating imap flags")
    
    // TODO: handle this force unwrap
    try await runOperation(session.storeFlagsOperation(
      withFolder: DefaultFolder,
      uids: uidSet,
      kind: operation,
      flags: flags
    ))

    // TODO: update from server instead?
    await managedObjectContext?.perform {
      switch operation {
        case .add:
          self.addFlags(flags)
        case .remove:
          self.removeFlags(flags)
        case .set:
          self.addFlags(flags)
        @unknown default:
          fatalError()
      }
    }
  }
  
  func addFlags(_ _flags: MCOMessageFlag) {
    var newFlags = flags
    newFlags.insert(_flags)
    flags = newFlags
  }
  
  func removeFlags(_ _flags: MCOMessageFlag) {
    var newFlags = flags
    newFlags.remove(_flags)
    flags = newFlags
  }
  
}

// MARK: - LABELS

extension Email {
  
  func moveToTrash() async throws {
    print("moving email to trash")
    
    // TODO: replace this with refetch email from server so gmailLabels update
    await managedObjectContext?.perform {
      self.labels.insert(cTrashLabel)
      self.labels.remove(cInboxLabel)
      self.addFlags(.deleted)
      self.trashed = true
    }
    
    try await updateLabels([cTrashLabel], operation: .add)
    try await updateLabels([cInboxLabel], operation: .remove)
    try await runOperation(session.expungeOperation("INBOX"))
  }
  
  func restoreFromTrash() async throws {
    print("restoring email from trash")
    
    await managedObjectContext?.perform {
      self.labels.insert(cInboxLabel)
      self.labels.remove(cTrashLabel)
      self.removeFlags(.deleted)
      self.trashed = false
    }
    
    try await updateLabels([cTrashLabel], operation: .remove)
    try await updateLabels([cInboxLabel], operation: .add)
  }
  
  func addLabels(_ labels: [String]) async throws {
    print("adding imap labels \(labels)")
    
    try await updateLabels(labels, operation: .add)
    await managedObjectContext?.perform {
      labels.forEach{ self.labels.insert($0) }
    }
  }
  
  func removeLabels(_ labels: [String]) async throws {
    print("removing imap labels \(labels)")
    
    try await updateLabels(labels, operation: .remove)
    await managedObjectContext?.perform {
      labels.forEach { self.labels.remove($0) }
    }
  }
  
  func updateLabels(_ labels: [String], operation: MCOIMAPStoreFlagsRequestKind) async throws {
    try await runOperation(session.storeLabelsOperation(withFolder: DefaultFolder,
                                                        uids: uidSet,
                                                        kind: operation,
                                                        labels: labels))
  }
  
}

// MARK: - FOLDERS

extension Email {
  
  func moveToJunk() async throws {
    print("moving \(subject) to junk")
    
    let moveOp = session.moveMessagesOperation(withFolder: DefaultFolder, uids: uidSet, destFolder: cJunkFolder)
    
    return try await withCheckedThrowingContinuation { continuation in
      moveOp?.start { error, uidDict in
        if let error = error {
          continuation.resume(throwing: PsyError.unexpectedError(error))
          return
        }
        
        continuation.resume()
      }
    }
  }
  
}

// MARK: - SENDING

extension Email {
  
  func sendReply(_ replyText: String) async throws {
    let smtpSession = MCOSMTPSession()
    smtpSession.hostname = "smtp.gmail.com"
    smtpSession.port = 465
    smtpSession.username = account.address
    smtpSession.authType = .xoAuth2
    smtpSession.oAuth2Token = account.accessToken
    smtpSession.connectionType = .TLS
    
    let builder = MCOMessageBuilder()
    let replyFrom = to!.first(where: { $0.address == account.address })!
    let replyTo = [MCOAddress(displayName: from.displayName, mailbox: from.address)!]
    + to!
      .filter { $0.address != account.address }
      .map { MCOAddress(displayName: $0.displayName, mailbox: $0.address)! }
    
    builder.header.from = MCOAddress(displayName: replyFrom.displayName, mailbox: replyFrom.address)
    builder.header.to = replyTo
    builder.header.cc = cc?.map { MCOAddress(displayName: $0.displayName, mailbox: $0.address)! } ?? []
    builder.header.cc = bcc?.map { MCOAddress(displayName: $0.displayName, mailbox: $0.address)! } ?? []
    builder.header.replyTo = [builder.header.from!]
    builder.header.inReplyTo = [String(messageId)]
    builder.header.references = [String(messageId)]
    builder.header.subject = subjectRaw.contains("Re:") ? subjectRaw : "Re: \(subjectRaw)"

    let formattedDate = EmailDateFormatter.moreThanAWeekLongStyle.string(from: receivedDate)
    builder.htmlBody = """
      <body>
        <div>\(replyText)</div>
        <br><br>
        <blockquote>
          On \(formattedDate), \(from.displayName ?? "") &lt;<a href="mailto:\(from.address)">\(from.address)</a>&gt; wrote:
          <br ><br >
          \(html)
        </blockquote>
      </body>
    """
    
    do {
      try await runOperation(smtpSession.sendOperation(with: builder.data()))
      print("reply sent!")
    }
    catch {
      print("error sending message: \(error.localizedDescription)")
      throw error
    }
  }
  
}

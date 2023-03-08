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
    gmailLabels = Set(message.gmailLabels as? [String] ?? [])
    gmailMessageId = Int64(message.gmailMessageID)
    gmailThreadId = Int64(message.gmailThreadID)
    size = Int32(message.size)
    originalFlags = message.originalFlags
    customFlags = Set(message.customFlags as? [String] ?? [])
    modSeqValue = Int64(message.modSeqValue)
    html = ""
    trashed = false
    isLatestInThread = false
    
    let header = message.header!
    receivedDate = header.receivedDate
    sentDate = header.date
    subjectRaw = header.subject ?? ""
    userAgent = header.userAgent
    references = Set(header.references as? [String] ?? [])
    
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
  
  private func runOperation(_ op: MCOIMAPOperation) async throws {
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
  
  func markSeen() async throws {
    try await updateFlags(.seen, operation: .add)
  }
  
  func markFlagged() async throws {
    try await updateFlags(.flagged, operation: .add)
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
  
  func updateFlags(_ flags: MCOMessageFlag, operation: MCOIMAPStoreFlagsRequestKind) async throws {
    print("updating imap flags")
    
    guard let updateFlags = session.storeFlagsOperation( // TODO: handle this force unwrap
      withFolder: DefaultFolder,
      uids: uidSet,
      kind: .add,
      flags: .seen
    ) else {
      throw PsyError.unexpectedError(message: "error creating update flags operation")
    }
    
    try await runOperation(updateFlags)
    addFlags(.seen) // TODO: update from server instead?
  }
  
}

// MARK: - LABELS

extension Email {
  
  func moveToTrash() async throws {
    print("moving emails to trash")
    try await updateLabels([cTrashLabel], operation: .add)
    try await updateLabels([cInboxLabel], operation: .remove)
    
    guard let expunge = session.expungeOperation("INBOX")
    else {
      throw PsyError.unexpectedError(message: "error creating expunge operation")
    }
    try await runOperation(expunge)

    // TODO: replace this with refetch email from server so gmailLabels update
    gmailLabels.insert(cTrashLabel)
    gmailLabels.remove(cInboxLabel)
    addFlags(.deleted)
    trashed = true
  }
  
  func addLabels(_ labels: [String]) async throws {
    print("adding imap labels \(labels)")
    try await updateLabels(labels, operation: .add)
    labels.forEach{ gmailLabels.insert($0) }
  }
  
  func removeLabels(_ labels: [String]) async throws {
    print("removing imap labels \(labels)")
    try await updateLabels(labels, operation: .remove)
    labels.forEach { gmailLabels.remove($0) }
  }
  
  func updateLabels(_ labels: [String], operation: MCOIMAPStoreFlagsRequestKind) async throws {
    guard let addTrashLabel = session.storeLabelsOperation(withFolder: DefaultFolder,
                                                            uids: uidSet,
                                                            kind: .add,
                                                            labels: labels)
    else {
      throw PsyError.unexpectedError(message: "error creating label update operations")
    }

    try await runOperation(addTrashLabel)
  }
  
}

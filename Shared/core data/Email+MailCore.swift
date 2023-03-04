import Foundation
import CoreData
import MailCore


private let accountCtrl = AccountController.shared
private let dataCtrl = PersistenceController.shared


extension Email {
  
  var seen: Bool { flags.contains(.seen) }
  var uidSet: MCOIndexSet { MCOIndexSet(index: UInt64(uid)) }
  
  var session: MCOIMAPSession? {
    if let account = account {
      return accountCtrl.sessions[account]
    }
    else { return nil }
  }
  
  // MARK: - INIT
  
  convenience init(
    message: MCOIMAPMessage, html emailAsHtml: String? = nil,
    bundleName: String? = nil, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.populate(message: message, html: html, bundleName: bundleName, context: context)
  }
  
  func populate(message: MCOIMAPMessage, html emailAsHtml: String? = nil,
                bundleName: String? = nil, context: NSManagedObjectContext) {
    populate(message: message, html: emailAsHtml)
    
    header = EmailHeader(header: message.header, context: context)
    header?.email = self
    
    if let part = message.mainPart {
      mimePart = EmailPart(part: part, context: context)
      mimePart?.email = self
    }
    
//    thread = fetchOrMakeThread(id: message.gmailThreadID, context: context)
//    thread?.addToEmails(self)
    
    if let bundleName = bundleName {
      let bundleFetchRequest = EmailBundle.fetchRequest()
      bundleFetchRequest.predicate = NSPredicate(format: "name == %@", bundleName)
      bundleFetchRequest.fetchLimit = 1
      bundleFetchRequest.fetchBatchSize = 1
      
      let bundle = try! context.fetch(bundleFetchRequest).first!
      
      bundle.addToEmailSet(self)
      addToBundleSet(bundle)
    }
  }
  
  func populate(message: MCOIMAPMessage, html emailAsHtml: String? = nil) {
    uid = Int32(message.uid)
    flags = message.flags
    gmailLabels = Set(message.gmailLabels as? [String] ?? [])
    gmailMessageId = Int64(message.gmailMessageID)
    size = Int32(message.size)
    originalFlags = message.originalFlags
    customFlags = Set(message.customFlags as? [String] ?? [])
    modSeqValue = Int64(message.modSeqValue)
    html = emailAsHtml ?? ""
    trashed = false
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
    guard let fetchMessage = session?.fetchParsedMessageOperation(withFolder: DefaultFolder,
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
    
    guard let updateFlags = session!.storeFlagsOperation( // TODO: handle this force unwrap
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
    try await updateLabels(["\\Trash"], operation: .add)
    
    guard let expunge = session?.expungeOperation("INBOX")
    else {
      throw PsyError.unexpectedError(message: "error creating expunge operation")
    }
    try await runOperation(expunge)

    // TODO: replace this with refetch email from server so gmailLabels update
    gmailLabels.insert("\\Trash")
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
    guard let addTrashLabel = session?.storeLabelsOperation(withFolder: DefaultFolder,
                                                            uids: uidSet,
                                                            kind: .add,
                                                            labels: labels)
    else {
      throw PsyError.unexpectedError(message: "error creating label update operations")
    }

    try await runOperation(addTrashLabel)
  }
  
}

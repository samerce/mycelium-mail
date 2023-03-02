import Foundation
import CoreData
import MailCore


private let mailCtrl = MailController.shared


extension Email {
  
  var moc: NSManagedObjectContext? { managedObjectContext }
  var session: MCOIMAPSession? {
    if let account = account {
      return mailCtrl.sessions[account]
    }
    else { return nil }
  }
  
  
  private func uidSetForEmails(_ emails: [Email]) -> MCOIndexSet {
    let uidSet = MCOIndexSet()
    for email in emails {
      uidSet.add(UInt64(email.uid))
    }
    return uidSet
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
    
    html = try await self.bodyHtml()
    
    try await moc?.perform {
      try self.moc?.save()
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
  
  func markSeen() async throws {
    try await updateFlags(.seen, operation: .add)
  }
  
  func markFlagged() async throws {
    try await updateFlags(.flagged, operation: .add)
  }
  
  func updateFlags(_ flags: MCOMessageFlag, operation: MCOIMAPStoreFlagsRequestKind) async throws {
    print("adding flags")
    let queue = OperationQueue()
    
    guard let updateFlags = session!.storeFlagsOperation( // TODO: handle this force unwrap
      withFolder: DefaultFolder,
      uids: uidSetForEmails([self]),
      kind: .add,
      flags: .seen
    ) else {
      throw PsyError.unexpectedError(message: "error creating update flags operation")
    }
    
    let _: Any? = try await withCheckedThrowingContinuation { continuation in
      updateFlags.start { _error in
        if let _error = _error {
          continuation.resume(
            throwing: PsyError.unexpectedError(message: "error setting flags: \(_error.localizedDescription)")
          )
        }
        
        do {
          self.addFlags(.seen)
          try self.moc!.save() // TODO: handle this force unwrap
        } catch {
          continuation.resume(
            throwing: PsyError.unexpectedError(message: "failed to add core data .seen flag to \(self)")
          )
        }
      }
    }
  }
  
}

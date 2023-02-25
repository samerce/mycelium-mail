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
  
  func fetchHtml() async throws {
    guard html.isEmpty
    else { return }

    html = try await self.bodyHtml()

    try await moc?.perform {
      try self.moc?.save()
    }
  }

  func bodyHtml() async throws -> String {
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


private func sessionForType(_ accountType: AccountType) -> MCOIMAPSession {
  switch accountType {
  case .gmail:
    return GmailSession()
  }
}

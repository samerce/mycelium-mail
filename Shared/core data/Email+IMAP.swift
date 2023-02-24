import Foundation
import CoreData
import MailCore


extension Email {
  
  private var moc: NSManagedObjectContext? { managedObjectContext }
  private var session: MCOIMAPSession? {
    account?.type == nil ? nil : sessionForType(account!.type)
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
    let fetchMessage = session?.fetchParsedMessageOperation(withFolder: DefaultFolder,
                                                            uid: UInt32(uid))

    return try await withCheckedThrowingContinuation { continuation in
      guard let fetchMessage = fetchMessage else {
        continuation.resume(
          throwing: PsyError.unexpectedError(message: "failed to create fetch HTML operation")
        )
        return
      }

      fetchMessage.start() { (error: Error?, parser: MCOMessageParser?) in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: parser?.htmlBodyRendering() ?? "")
        }
      }
    }
  }

  func fullHtmlForEmail(_ completion: @escaping (String?) -> Void) {
    let fetchMessage = session?.fetchParsedMessageOperation(withFolder: DefaultFolder, uid: UInt32(uid))
    fetchMessage?.start() { (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlRendering(with: nil) ?? "")
    } ?? completion("")
  }
  
  // MARK: - HELPERS
  
}


private func sessionForType(_ accountType: AccountType) -> MCOIMAPSession {
  switch accountType {
  case .gmail:
    return GmailSession()
  }
}

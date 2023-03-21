import Foundation
import CoreData
import MailCore


extension EmailThread {
  
  func hydrateWithMessage(_ message: MCOIMAPMessage) {
    self.id = Int64(message.gmailThreadID)
    self.subject = message.header?.subject?.replacingOccurrences(of: "\r\n", with: "") ?? ""
    self.lastMessageDate = message.header?.receivedDate ?? .now
  }
  
  func addLabels(_ labels: [String]) async throws {
    for email in emails {
      try await email.addLabels(labels)
    }
  }
  
  func removeLabels(_ labels: [String]) async throws {
    for email in emails {
      try await email.removeLabels(labels)
    }
  }
  
  func moveToTrash() async throws {
    for email in emails {
      try await email.moveToTrash()
    }
    trashed = true
  }
  
  func moveToJunk() async throws {
    for email in emails {
      try await email.moveToJunk()
    }
    trashed = true // TODO: separate property for spam?
  }
  
  func markSeen(_ seen: Bool = true) async throws {
    for email in emails {
      try await email.markSeen(seen)
    }
  }
  
  func markFlagged(_ flagged: Bool = true) async throws {
    for email in emails {
      try await email.markFlagged(flagged)
    }
    
    try await managedObjectContext?.perform {
      self.bundle.removeFromThreadSet(self)
      
      let newBundleName = flagged ? "starred" : try self.calculatedBundleName()
      let newBundle = try EmailBundle.fetchRequestWithName(newBundleName).execute().first!
      
      newBundle.addToThreadSet(self)
      self.bundle = newBundle
    }
  }
  
  func archive() async throws {
    for email in emails {
      try await email.archive()
    }
    
    try await managedObjectContext?.perform {
      self.bundle.removeFromThreadSet(self)
      
      let archiveBundle = try EmailBundle.fetchRequestWithName("archive").execute().first!
      archiveBundle.addToThreadSet(self)
      self.bundle = archiveBundle
    }
  }
  
  private func calculatedBundleName() throws -> String {
    guard let firstReceivedEmail = self.emails.first(where: { $0.from.address != self.account.address })
    else { throw PsyError.unexpectedError() }
    
    return MailController.shared.bundleNameForEmail(firstReceivedEmail)!
  }
  
}

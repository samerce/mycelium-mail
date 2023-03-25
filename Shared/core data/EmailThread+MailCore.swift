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
  }
  
}

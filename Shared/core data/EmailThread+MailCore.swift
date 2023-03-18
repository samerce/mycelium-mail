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
  
  func markSeen() async throws {
    for email in emails {
      try await email.markSeen()
    }
  }
  
  func markFlagged() async throws {
    for email in emails {
      try await email.markFlagged()
    }
  }
  
}

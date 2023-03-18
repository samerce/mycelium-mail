import Foundation
import CoreData

extension EmailThread {
  
  var emails: [Email] {
    Set(_immutableCocoaSet: emailSet).sorted { $0.receivedDate > $1.receivedDate }
  }
  
  var seen: Bool {
    emails.allSatisfy { $0.seen }
  }
  
  var fromLine: String {
    latestReceivedEmail.fromLine
  }
  
  var from: EmailAddress {
    latestReceivedEmail.from
  }
  
  var displayDate: String {
    latestReceivedEmail.displayDate ?? "unknown"
  }
  
  var latestReceivedEmail: Email {
    emails.first(where: { $0.from.address != account.address })!
  }
  
  @NSManaged public var id: Int64
  @NSManaged public var lastMessageDate: Date
  @NSManaged public var subject: String
  @NSManaged public var trashed: Bool
  @NSManaged public var bundle: EmailBundle
  @NSManaged public var account: Account
  @NSManaged public var emailSet: NSSet
  
}

// MARK: Generated accessors for emails
extension EmailThread {
  
  @objc(addEmailSetObject:)
  @NSManaged public func addToEmailSet(_ value: Email)
  
  @objc(removeEmailSetObject:)
  @NSManaged public func removeFromEmailSet(_ value: Email)
  
  @objc(addEmailSet:)
  @NSManaged public func addToEmailSet(_ values: NSSet)
  
  @objc(removeEmailSet:)
  @NSManaged public func removeFromEmailSet(_ values: NSSet)
  
}

extension EmailThread : Identifiable {
  
}

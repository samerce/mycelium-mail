import Foundation
import CoreData
import OrderedCollections


extension EmailThread {
  
  var emails: [Email] {
    Set(_immutableCocoaSet: emailSet).sorted { $0.receivedDate > $1.receivedDate }
  }
  
  var seen: Bool {
    emails.allSatisfy { $0.seen }
  }
  
  var flagged: Bool {
    emails.contains(where: { $0.flagged })
  }
  
  var fromLine: String {
    let senders = emails.reduce(into: OrderedSet<String>()) { line, email in
      guard let name = email.from.displayName?.split(separator: " ").first,
            (email.sender?.address != email.account.address &&
             email.from.address != email.account.address)
      else {
        return
      }
      line.append(String(name))
    }
    
    if emails.count == 1 || senders.count == 1 {
      return emails.first!.fromLine
    }
      
    return senders.joined(separator: ", ")
  }
  
  var from: [EmailAddress] {
    emails
      .filter { $0.from.address != $0.account.address && $0.sender?.address != $0.account.address }
      .map { $0.from }
      .removingDuplicates()
  }
  
  var displayDate: String {
    lastReceivedEmail.displayDate ?? "unknown"
  }
  
  var lastReceivedEmail: Email {
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

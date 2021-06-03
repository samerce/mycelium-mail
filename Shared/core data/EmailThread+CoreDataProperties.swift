import Foundation
import CoreData

extension EmailThread {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailThread> {
    return NSFetchRequest<EmailThread>(entityName: "EmailThread")
  }
  
  @NSManaged public var id: Int64
  @NSManaged public var emails: NSSet?
  
}

// MARK: Generated accessors for emails
extension EmailThread {
  
  @objc(addEmailsObject:)
  @NSManaged public func addToEmails(_ value: Email)
  
  @objc(removeEmailsObject:)
  @NSManaged public func removeFromEmails(_ value: Email)
  
  @objc(addEmails:)
  @NSManaged public func addToEmails(_ values: NSSet)
  
  @objc(removeEmails:)
  @NSManaged public func removeFromEmails(_ values: NSSet)
  
}

extension EmailThread : Identifiable {
  
}

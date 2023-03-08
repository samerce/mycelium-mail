import Foundation
import CoreData


extension EmailBundle {
  
  var emails: [Email] {
    (emailSet.allObjects as? [Email]) ?? []
  }
  
  @NSManaged public var name: String
  @NSManaged public var icon: String
  @NSManaged public var labelId: String
  @NSManaged public var orderIndex: Int16
  @NSManaged public var lastSeenDate: Date
  @NSManaged public var newEmailsSinceLastSeen: Int64
  @NSManaged public var emailSet: NSSet
  
}


// MARK: - Generated accessors for emails

extension EmailBundle {
  
  @objc(addEmailSetObject:)
  @NSManaged public func addToEmailSet(_ value: Email)
  
  @objc(removeEmailSetObject:)
  @NSManaged public func removeFromEmailSet(_ value: Email)
  
  @objc(addEmailSet:)
  @NSManaged public func addToEmailSet(_ values: NSSet)
  
  @objc(removeEmailSet:)
  @NSManaged public func removeFromEmailSet(_ values: NSSet)
  
}

extension EmailBundle : Identifiable {
  
}

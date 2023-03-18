import Foundation
import CoreData


extension EmailBundle {
  
  var threads: [EmailThread] {
    (threadSet.allObjects as? [EmailThread]) ?? []
  }
  
  @NSManaged public var name: String
  @NSManaged public var icon: String
  @NSManaged public var labelId: String
  @NSManaged public var orderIndex: Int16
  @NSManaged public var lastSeenDate: Date
  @NSManaged public var newEmailsSinceLastSeen: Int64
  @NSManaged public var threadSet: NSSet
  
}


// MARK: - Generated accessors for emails

extension EmailBundle {
  
  @objc(addThreadSetObject:)
  @NSManaged public func addToThreadSet(_ value: EmailThread)
  
  @objc(removeThreadSetObject:)
  @NSManaged public func removeFromThreadSet(_ value: EmailThread)
  
  @objc(addThreadSet:)
  @NSManaged public func addToThreadSet(_ values: NSSet)
  
  @objc(removeThreadSet:)
  @NSManaged public func removeFromThreadSet(_ values: NSSet)
  
}

extension EmailBundle : Identifiable {
  
}

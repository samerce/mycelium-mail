import Foundation
import CoreData

extension Account {
  
  var moc: NSManagedObjectContext? { managedObjectContext }
  
  var type: AccountType {
    get {
      return AccountType(rawValue: typeRaw!)!
    }
    set {
      typeRaw = newValue.rawValue
    }
  }
  
  var fullName: String? {
    if let firstName = firstName {
      return firstName + (lastName ?? "")
    }
    return nil
  }
  
  var threads: [EmailThread] {
    (threadSet.allObjects as? [EmailThread]) ?? []
  }
  
  @NSManaged public var accessToken: String?
  @NSManaged public var accessTokenExpiration: Date?
  @NSManaged public var address: String
  @NSManaged public var firstName: String?
  @NSManaged public var lastName: String?
  @NSManaged public var password: String?
  @NSManaged public var refreshToken: String?
  @NSManaged public var typeRaw: String?
  @NSManaged public var userId: String
  @NSManaged public var nickname: String
  
  @NSManaged public var threadSet: NSSet
  @NSManaged public var emailSet: NSSet
  
}

// MARK: Generated accessors for emails
extension Account {
  
  @objc(addThreadSetObject:)
  @NSManaged public func addToThreadSet(_ value: EmailThread)
  
  @objc(removeThreadSetObject:)
  @NSManaged public func removeFromThreadSet(_ value: EmailThread)
  
  @objc(addThreadSet:)
  @NSManaged public func addToThreadSet(_ values: NSSet)
  
  @objc(removeThreadSet:)
  @NSManaged public func removeFromThreadSet(_ values: NSSet)
  
}

extension Account {
  
  @objc(addEmailSetObject:)
  @NSManaged public func addToEmailSet(_ value: Email)
  
  @objc(removeEmailSetObject:)
  @NSManaged public func removeFromEmailSet(_ value: Email)
  
  @objc(addEmailSet:)
  @NSManaged public func addToEmailSet(_ values: NSSet)
  
  @objc(removeEmailSet:)
  @NSManaged public func removeFromEmailSet(_ values: NSSet)
  
}

extension Account : Identifiable {
  
}

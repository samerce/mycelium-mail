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
  
  @NSManaged public var accessToken: String?
  @NSManaged public var accessTokenExpiration: Date?
  @NSManaged public var address: String
  @NSManaged public var emails: NSSet?
  @NSManaged public var firstName: String?
  @NSManaged public var lastName: String?
  @NSManaged public var password: String?
  @NSManaged public var refreshToken: String?
  @NSManaged public var typeRaw: String?
  @NSManaged public var userId: String
  
}

// MARK: Generated accessors for emails
extension Account {
  
  @objc(addEmailsObject:)
  @NSManaged public func addToEmails(_ value: Email)
  
  @objc(removeEmailsObject:)
  @NSManaged public func removeFromEmails(_ value: Email)
  
  @objc(addEmails:)
  @NSManaged public func addToEmails(_ values: NSSet)
  
  @objc(removeEmails:)
  @NSManaged public func removeFromEmails(_ values: NSSet)
  
}

extension Account : Identifiable {
  
}

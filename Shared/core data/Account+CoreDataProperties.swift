//
//  Account+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/31/21.

import Foundation
import CoreData

extension Account {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
    return NSFetchRequest<Account>(entityName: "Account")
  }
  
  @NSManaged public var username: String?
  @NSManaged public var oAuthToken: String?
  @NSManaged public var password: String?
  @NSManaged public var typeRaw: String?
  @NSManaged public var address: String?
  @NSManaged public var emails: NSSet?
  
  var type: AccountType {
    get {
      return AccountType(rawValue: typeRaw!)!
    }
    set {
      typeRaw = newValue.rawValue
    }
  }
  
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

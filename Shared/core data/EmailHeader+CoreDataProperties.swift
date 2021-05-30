//
//  EmailHeader+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/30/21.
//
//

import Foundation
import CoreData


extension EmailHeader {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailHeader> {
    return NSFetchRequest<EmailHeader>(entityName: "EmailHeader")
  }
  
  @NSManaged public var inReplyTo: [String]?
  @NSManaged public var receivedDate: Date?
  @NSManaged public var sentDate: Date?
  @NSManaged public var subject: String?
  @NSManaged public var userAgent: String?
  @NSManaged public var references: [String]?
  @NSManaged public var from: EmailAddress?
  @NSManaged public var email: Email?
  @NSManaged public var bcc: NSSet?
  @NSManaged public var cc: NSSet?
  @NSManaged public var replyTo: NSSet?
  @NSManaged public var sender: EmailAddress?
  @NSManaged public var to: NSSet?
  
}

// MARK: Generated accessors for bcc
extension EmailHeader {
  
  @objc(addBccObject:)
  @NSManaged public func addToBcc(_ value: EmailAddress)
  
  @objc(removeBccObject:)
  @NSManaged public func removeFromBcc(_ value: EmailAddress)
  
  @objc(addBcc:)
  @NSManaged public func addToBcc(_ values: NSSet)
  
  @objc(removeBcc:)
  @NSManaged public func removeFromBcc(_ values: NSSet)
  
}

// MARK: Generated accessors for cc
extension EmailHeader {
  
  @objc(addCcObject:)
  @NSManaged public func addToCc(_ value: EmailAddress)
  
  @objc(removeCcObject:)
  @NSManaged public func removeFromCc(_ value: EmailAddress)
  
  @objc(addCc:)
  @NSManaged public func addToCc(_ values: NSSet)
  
  @objc(removeCc:)
  @NSManaged public func removeFromCc(_ values: NSSet)
  
}

// MARK: Generated accessors for replyTo
extension EmailHeader {
  
  @objc(addReplyToObject:)
  @NSManaged public func addToReplyTo(_ value: EmailAddress)
  
  @objc(removeReplyToObject:)
  @NSManaged public func removeFromReplyTo(_ value: EmailAddress)
  
  @objc(addReplyTo:)
  @NSManaged public func addToReplyTo(_ values: NSSet)
  
  @objc(removeReplyTo:)
  @NSManaged public func removeFromReplyTo(_ values: NSSet)
  
}

// MARK: Generated accessors for to
extension EmailHeader {
  
  @objc(addToObject:)
  @NSManaged public func addToTo(_ value: EmailAddress)
  
  @objc(removeToObject:)
  @NSManaged public func removeFromTo(_ value: EmailAddress)
  
  @objc(addTo:)
  @NSManaged public func addToTo(_ values: NSSet)
  
  @objc(removeTo:)
  @NSManaged public func removeFromTo(_ values: NSSet)
  
}

extension EmailHeader : Identifiable {
  
}

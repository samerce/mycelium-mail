//
//  EmailAddress+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/30/21.

import Foundation
import CoreData

extension EmailAddress {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailAddress> {
    return NSFetchRequest<EmailAddress>(entityName: "EmailAddress")
  }
  
  @NSManaged public var address: String?
  @NSManaged public var displayName: String?
  @NSManaged public var header: EmailHeader?
  
  // MARK: - not used, always nil
  @NSManaged public var toHeader: EmailHeader?
  @NSManaged public var bccHeader: EmailHeader?
  @NSManaged public var ccHeader: EmailHeader?
  @NSManaged public var replyToHeader: EmailHeader?
  @NSManaged public var senderHeader: EmailHeader?
  
}

extension EmailAddress : Identifiable {
  
}

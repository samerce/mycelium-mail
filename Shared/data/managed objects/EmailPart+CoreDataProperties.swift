//
//  EmailPart+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/30/21.

import Foundation
import CoreData
import MailCore

extension EmailPart {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailPart> {
    return NSFetchRequest<EmailPart>(entityName: "EmailPart")
  }
  
  @NSManaged public var charset: String?
  @NSManaged public var contentDescription: String?
  @NSManaged public var contentId: String?
  @NSManaged public var contentLocation: String?
  @NSManaged public var filename: String?
  @NSManaged public var isAttachment: Bool
  @NSManaged public var isInlineAttachment: Bool
  @NSManaged public var mimeType: String?
  @NSManaged public var partTypeRaw: Int16
  @NSManaged public var uid: String?
  @NSManaged public var email: Email?
  
  var partType: MCOPartType {
    get {
      return MCOPartType(rawValue: Int(partTypeRaw))!
    }
    set {
      partTypeRaw = Int16(newValue.rawValue)
    }
  }
  
}

extension EmailPart : Identifiable {
  
}

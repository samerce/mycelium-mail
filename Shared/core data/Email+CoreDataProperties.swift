//
//  Email+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/30/21.

import Foundation
import CoreData
import MailCore

extension Email {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Email> {
    return NSFetchRequest<Email>(entityName: "Email")
  }
  
  @NSManaged public var customFlags: Set<String>?
  @NSManaged public var date: Date?
  @NSManaged public var flagsRaw: Int16
  @NSManaged public var gmailLabels: Set<String>?
  @NSManaged public var gmailMessageId: Int64
  @NSManaged public var gmailThreadId: Int64
  @NSManaged public var html: String?
  @NSManaged public var modSeqValue: Int64 // last mod seq on server, see RFC4551
  @NSManaged public var originalFlagsRaw: Int16 // flags when first fetched
  @NSManaged public var perspective: String? // aka ai category
  @NSManaged public var size: Int32
  @NSManaged public var uid: Int32 // email id from server
  @NSManaged public var uuid: UUID? // core data id
  @NSManaged public var header: EmailHeader?
  @NSManaged public var mimePart: EmailPart?
  @NSManaged public var account: Account?
  
  var flags: MCOMessageFlag {
    get {
      return MCOMessageFlag(rawValue: Int(flagsRaw))
    }
    set {
      flagsRaw = Int16(newValue.rawValue)
    }
  }
  
  var originalFlags: MCOMessageFlag {
    get {
      return MCOMessageFlag(rawValue: Int(originalFlagsRaw))
    }
    set {
      originalFlagsRaw = Int16(newValue.rawValue)
    }
  }
  
}

extension Email : Identifiable {
  
}

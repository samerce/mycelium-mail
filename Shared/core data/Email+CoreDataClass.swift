//
//  Email+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/27/21.

import Foundation
import CoreData
import MailCore

@objc(Email)
public class Email: NSManagedObject {
  
  var seen: Bool {
    flags.contains(.seen)
  }
  
  convenience init(
    message: MCOIMAPMessage, html emailAsHtml: String?,
    perspective _perspective: String, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    
    uuid = UUID()
    uid = Int32(message.uid)
    flags = message.flags
    gmailLabels = Set(message.gmailLabels as? [String] ?? [])
    gmailThreadId = Int64(message.gmailThreadID)
    gmailMessageId = Int64(message.gmailMessageID)
    size = Int32(message.size)
    originalFlags = message.originalFlags
    customFlags = Set(message.customFlags as? [String] ?? [])
    modSeqValue = Int64(message.modSeqValue)
    html = emailAsHtml
    perspective = _perspective
    
    header = EmailHeader(header: message.header, context: context)
    header?.email = self
    
    if let part = message.mainPart {
      mimePart = EmailPart(part: part, context: context)
      mimePart?.email = self
    }
  }
  
  func setFlags(_ setFlags: [MCOMessageFlag]) {
    var newFlags = flags
    for flag in setFlags {
      newFlags.insert(flag)
    }
    flags = newFlags
  }
  
  func removeFlags(_ removeFlags: [MCOMessageFlag]) {
    var newFlags = flags
    for flag in removeFlags {
      newFlags.remove(flag)
    }
    flags = newFlags
  }

}

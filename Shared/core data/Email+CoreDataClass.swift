//
//  Email+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData
import MailCore

@objc(Email)
public class Email: NSManagedObject {
  
  var seen: Bool {
    MCOMessageFlag(rawValue: Int(flags)).contains(.seen)
  }
  
  convenience init(
    message: MCOIMAPMessage, html emailAsHtml: String?,
    perspective _perspective: String, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    
    uid = Int32(message.uid)
    flags = Int16(message.flags.rawValue)
//    email.gmailLabels = message.gmailLabels
    gmailThreadId = Int64(message.gmailThreadID)
    gmailMessageId = Int64(message.gmailMessageID)
    date = message.header.receivedDate
//    email.sender = email.header.from
    size = Int32(message.size)
    originalFlags = Int16(message.originalFlags.rawValue)
    customFlags = (message.customFlags as! Array).joined(separator: ",")
    modSeqValue = Int64(message.modSeqValue)
    html = emailAsHtml
    perspective = _perspective
    
    header = EmailHeader(header: message.header, context: managedObjectContext!)
    header?.email = self

    mimePart = EmailPart(part: message.mainPart, context: managedObjectContext!)
    mimePart?.email = self
  }

  func markSeen() {
    var newFlags = MCOMessageFlag(rawValue: Int(flags))
    newFlags.insert(.seen)
    flags = Int16(newFlags.rawValue)
  }
  
}

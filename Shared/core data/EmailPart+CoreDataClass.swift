//
//  EmailPart+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData
import MailCore

@objc(EmailPart)
public class EmailPart: NSManagedObject {
  
  convenience init(part: MCOAbstractPart, context: NSManagedObjectContext) {
    self.init(context: context)
    
    uid = part.uniqueID
    filename = part.filename
    mimeType = part.mimeType
    charset = part.charset
    contentId = part.contentID
    contentLocation = part.contentLocation
    contentDescription = part.contentDescription
    isInlineAttachment = part.isInlineAttachment
    isAttachment = part.isAttachment
    partType = Int16(part.partType.rawValue)
  }

}

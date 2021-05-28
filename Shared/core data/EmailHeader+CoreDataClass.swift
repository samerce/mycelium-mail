//
//  EmailHeader+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData
import MailCore

@objc(EmailHeader)
public class EmailHeader: NSManagedObject {
  
  convenience init(header: MCOMessageHeader, context: NSManagedObjectContext) {
    self.init(context: context)
    
//    inReplyTo = header?.inReplyTo
    sentDate = header.date
    receivedDate = header.receivedDate
//    header.to = header?.to
//    header.cc = header?.cc
//    header.bcc = header?.bcc
//    header.replyTo = header?.replyTo
    subject = header.subject
    userAgent = header.userAgent
    
    from = EmailAddress(
      displayName: header.from.displayName,
      address: header.from.mailbox,
      context: managedObjectContext!
    )
    from?.header = self
  }
  
}

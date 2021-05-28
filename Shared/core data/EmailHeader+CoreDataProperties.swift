//
//  EmailHeader+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData


extension EmailHeader {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailHeader> {
        return NSFetchRequest<EmailHeader>(entityName: "EmailHeader")
    }

    @NSManaged public var inReplyTo: NSObject?
    @NSManaged public var sentDate: Date?
    @NSManaged public var receivedDate: Date?
    @NSManaged public var to: NSObject?
    @NSManaged public var cc: NSObject?
    @NSManaged public var bcc: NSObject?
    @NSManaged public var replyTo: NSObject?
    @NSManaged public var subject: String?
    @NSManaged public var userAgent: String?
    @NSManaged public var email: Email?
    @NSManaged public var from: EmailAddress?

}

extension EmailHeader : Identifiable {

}

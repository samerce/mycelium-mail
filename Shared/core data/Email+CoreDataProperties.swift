//
//  Email+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/28/21.
//
//

import Foundation
import CoreData


extension Email {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Email> {
        return NSFetchRequest<Email>(entityName: "Email")
    }

    @NSManaged public var customFlags: String?
    @NSManaged public var date: Date?
    @NSManaged public var flags: Int16
    @NSManaged public var gmailLabels: NSObject?
    @NSManaged public var gmailMessageId: Int64
    @NSManaged public var gmailThreadId: Int64
    @NSManaged public var html: String?
    @NSManaged public var modSeqValue: Int64
    @NSManaged public var originalFlags: Int16
    @NSManaged public var perspective: String?
    @NSManaged public var sender: String?
    @NSManaged public var size: Int32
    @NSManaged public var uid: Int32
    @NSManaged public var header: EmailHeader?
    @NSManaged public var mimePart: EmailPart?

}

extension Email : Identifiable {

}

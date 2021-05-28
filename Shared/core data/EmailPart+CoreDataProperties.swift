//
//  EmailPart+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData


extension EmailPart {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailPart> {
        return NSFetchRequest<EmailPart>(entityName: "EmailPart")
    }

    @NSManaged public var uid: String?
    @NSManaged public var filename: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var charset: String?
    @NSManaged public var contentId: String?
    @NSManaged public var contentLocation: String?
    @NSManaged public var contentDescription: String?
    @NSManaged public var isInlineAttachment: Bool
    @NSManaged public var isAttachment: Bool
    @NSManaged public var partType: Int16
    @NSManaged public var email: Email?

}

extension EmailPart : Identifiable {

}

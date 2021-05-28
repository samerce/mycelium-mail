//
//  EmailAddress+CoreDataProperties.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData


extension EmailAddress {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailAddress> {
        return NSFetchRequest<EmailAddress>(entityName: "EmailAddress")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var address: String?
    @NSManaged public var header: EmailHeader?

}

extension EmailAddress : Identifiable {

}

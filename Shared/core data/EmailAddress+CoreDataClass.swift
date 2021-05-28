//
//  EmailAddress+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/27/21.
//
//

import Foundation
import CoreData

@objc(EmailAddress)
public class EmailAddress: NSManagedObject {
  
  convenience init(
    displayName: String, address: String, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.displayName = displayName
    self.address = address
  }

}

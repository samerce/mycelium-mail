//
//  EmailHeader+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/27/21.

import Foundation
import CoreData
import MailCore

@objc(EmailHeader)
public class EmailHeader: NSManagedObject {
  
  convenience init(header: MCOMessageHeader, context: NSManagedObjectContext) {
    self.init(context: context)
    
    inReplyTo = Set(header.inReplyTo as? [String] ?? [])
    receivedDate = header.receivedDate
    sentDate = header.date
    subject = header.subject
    userAgent = header.userAgent
    references = Set(header.references as? [String] ?? [])
    
    to = makeAddresses(header.to)
    bcc = makeAddresses(header.bcc)
    cc = makeAddresses(header.cc)
    replyTo = makeAddresses(header.replyTo)
    
    from = makeAddress(header.from)
    sender = header.sender != nil ? makeAddress(header.sender) : nil
  }
  
  private func makeAddresses(_ theirAddressesGeneric: [Any]?) -> NSSet {
    let myAddresses = NSMutableSet()
    
    if let theirAddresses = theirAddressesGeneric as? [MCOAddress] {
      for address in theirAddresses {
        myAddresses.add(makeAddress(address))
      }
    }
    
    return myAddresses
  }
  
  private func makeAddress(_ theirAddress: MCOAddress) -> EmailAddress {
    let address = EmailAddress(
      displayName: theirAddress.displayName,
      address: theirAddress.mailbox,
      context: managedObjectContext!
    )
    address.header = self
    return address
  }
  
}

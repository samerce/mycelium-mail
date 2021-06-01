//
//  Account+CoreDataClass.swift
//  psymail
//
//  Created by bubbles on 5/30/21.

import Foundation
import CoreData
import MailCore

public enum AccountType: String {
  case gmail
}

@objc(Account)
public class Account: NSManagedObject {
  
  @Published var loggedIn = false
  
  convenience init(
    address: String, username: String, oAuthToken: String, type: AccountType,
    context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.address = address
    self.username = username
    self.oAuthToken = oAuthToken
    self.type = type
  }
  
}

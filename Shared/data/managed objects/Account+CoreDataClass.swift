import Foundation
import CoreData

public enum AccountType: String {
  case gmail
}

@objc(Account)
public class Account: NSManagedObject {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
    return NSFetchRequest<Account>(entityName: "Account")
  }
  
  convenience init(
    type: AccountType,
    address: String, userId: String,
    firstName: String?, lastName: String?,
    accessToken: String, accessTokenExpiration: Date, refreshToken: String,
    context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.type = type
    self.address = address
    self.userId = userId
    self.firstName = firstName
    self.lastName = lastName
    self.accessToken = accessToken
    self.accessTokenExpiration = accessTokenExpiration
    self.refreshToken = refreshToken
  }
  
}

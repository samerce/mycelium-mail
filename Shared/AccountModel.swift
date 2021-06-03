import Foundation
import CoreData

class AccountModel: ObservableObject {
  @Published private(set) var accounts = [String: Account]()
  
  private var moc:NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  
  init() {
//    do {
//      let deleteRequest = NSBatchDeleteRequest(fetchRequest: Account.fetchRequest())
//      try moc.execute(deleteRequest)
//    }
//    catch let error {
//      print("error deleting all accounts from core data: \(error)")
//    }
    
    do {
      let fetchedAccounts = try moc.fetch(Account.fetchRequest()) as [Account]
      for account in fetchedAccounts {
        accounts[account.address!] = account
      }
    }
    catch let error {
      print("error fetching accounts from core data: \(error.localizedDescription)")
    }
  }
  
  func makeAndSaveAccount(
    type: AccountType,
    address: String, userId: String, firstName: String?, lastName: String?,
    accessToken: String, accessTokenExpiration: Date, refreshToken: String
  ) -> Account? {
    let account = Account(
      type: type,
      address: address, userId: userId, firstName: firstName, lastName: lastName,
      accessToken: accessToken, accessTokenExpiration: accessTokenExpiration,
      refreshToken: refreshToken,
      context: moc
    )
    accounts[account.address!] = account
    
    do {
      try moc.save()
      return account
    } catch let error {
      print("error saving account: \(error.localizedDescription)")
    }
    return nil
  }
  
  func save() {
    do { try moc.save() } catch let error {
      print("error saving core data account: \(error.localizedDescription)")
    }
  }
  
}

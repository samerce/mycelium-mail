import Foundation
import CoreData

class AccountModel: ObservableObject {
  @Published private(set) var accounts = [String: Account]()
  
  private var moc:NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  
  init() {
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
  
  func makeAndSaveAccount(address: String,
                          username: String,
                          oAuthToken: String,
                          type: AccountType) -> Account? {
    let account = Account(
      address: address,
      username: username,
      oAuthToken: oAuthToken,
      type: type,
      context: moc
    )
    account.loggedIn = true
    accounts[account.address!] = account
    
    do {
      try moc.save()
      return account
    } catch let error {
      print("error saving account: \(error.localizedDescription)")
    }
    return nil
  }
  
}

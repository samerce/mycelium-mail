import Foundation
import GoogleSignIn
import MailCore


private let moc = PersistenceController.shared.container.viewContext
private let googleConfig: GIDConfiguration = GIDConfiguration(
  clientID: "941559531688-m6ve00j5ofshqf5ksfqng92ga7kbkbb6.apps.googleusercontent.com"
)


class AccountController: ObservableObject {
  static let shared = AccountController()

  @Published private(set) var accounts = [String: Account]()
  @Published private(set) var signedInAccounts = Set<Account>()
  @Published private(set) var sessions = [Account: MCOIMAPSession]()

  init() {
    do {
      let fetchedAccounts = try moc.fetch(Account.fetchRequest()) as [Account]
      for account in fetchedAccounts {
        accounts[account.address] = account
        
        if account.accessTokenExpiration?.compare(.now) == .orderedAscending {
          print("token expired, implement refreshing!")
          // call refresh token api:
          // https://developers.google.com/identity/protocols/oauth2/web-server#offline
        } else {
          initAccount(account)
        }
      }
    }
    catch let error {
      print("error fetching accounts from core data: \(error.localizedDescription)")
    }
  }
  
  // MARK: - public
  
  func signIn() {
    print("requesting sign-in")
    GIDSignIn.sharedInstance.signIn(
      with: googleConfig,
      presenting: UIApplication.shared.rootViewController!,
      hint: "",
      additionalScopes: [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.settings.basic"
      ]
    )
    
    // TODO: figure out why this is necessary
    Timer.after(10) { _ in
      if self.signedInAccounts.isEmpty {
        self.restoreSignIn()
      }
    }
  }
  
  func restoreSignIn() {
    print("restoring sign-in")
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      self.handleSignIn(for: user, withError: error)
    }
  }
  
  func handleGoogleUrl(_ url: URL) {
    GIDSignIn.sharedInstance.handle(url)
  }
  
  func refreshTokensIfNeeded() {
    
  }
  
  // MARK: - handling responses
  
  func handleSignIn(for user: GIDGoogleUser!, withError error: Error!) {
//    if let error = error {
//      if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
//        print("gmail: no one has signed in before or they have since signed out.")
//      } else {
//        print("\(error.localizedDescription)")
//      }
//      return
//    }
    
    guard let profile = user?.profile
    else { return }
    let auth = user.authentication

    var account = accounts[profile.email]
    if account == nil {
      account = Account(
        type: .gmail,
        address: profile.email,
        userId: user.userID ?? "",
        firstName: profile.givenName,
        lastName: profile.familyName,
        accessToken: auth.accessToken,
        accessTokenExpiration: auth.accessTokenExpirationDate,
        refreshToken: auth.refreshToken,
        context: moc
      )
      accounts[account!.address] = account
    } else {
      account!.accessToken = auth.accessToken
      account!.accessTokenExpiration = auth.accessTokenExpirationDate
      account!.refreshToken = auth.refreshToken
    }
    try? moc.save()
    
    guard let account = account
    else { return }
    
    initAccount(account)
  }
  
  private func initAccount(_ account: Account) {
    var session = sessions[account]
    if session == nil {
      session = sessionForType(account.type)
      sessions[account] = session
    }
    session!.username = account.address
    session!.oAuth2Token = account.accessToken
    session!.isVoIPEnabled = false

    Task {
      do {
        try await account.syncBundles()
      }
      catch {
        // TODO: handle error
        print("error syncing bundles with gmail: \(error.localizedDescription)")
      }
      
      
      print("\(account.address): signed in and synced!")
      DispatchQueue.main.async {
        self.signedInAccounts.insert(account)
      }
    }
  }
  
//  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
//    print("\(user.profile.email ?? "unknown") logged out")
//    model.accounts[user.profile.email]?.loggedIn = false
//  }
  
  private func sessionForType(_ accountType: AccountType) -> MCOIMAPSession {
    switch accountType {
    case .gmail:
      return GmailSession()
    }
  }
  
}


class GmailSession: MCOIMAPSession {
  
  override init() {
    super.init()
    hostname = "imap.gmail.com"
    port = 993
    authType = .xoAuth2
    connectionType = .TLS
    allowsFolderConcurrentAccessEnabled = true
  }
  
}


import Foundation
import GoogleSignIn

class AccountController: NSObject {
  static let shared = AccountController()
  @Published private(set) var model = AccountModel()
  
  private var config: GIDConfiguration = GIDConfiguration(
    clientID: "941559531688-m6ve00j5ofshqf5ksfqng92ga7kbkbb6.apps.googleusercontent.com"
  )
  
  // MARK: - public
  
  func signIn() {
    print("requesting sign-in")
    GIDSignIn.sharedInstance.signIn(
      with: config,
      presenting: UIApplication.shared.rootViewController!,
      hint: "",
      additionalScopes: ["https://mail.google.com/"]
    )
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
  
  // MARK: - handling responses
  
  func handleSignIn(for user: GIDGoogleUser!, withError error: Error!) {
    if let error = error {
//      if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
//        print("gmail: no one has signed in before or they have since signed out.")
//      } else {
//        print("\(error.localizedDescription)")
//      }
      return
    }
    
    let profile = user.profile!
    let auth = user.authentication

    var account = model.accounts[profile.email]
    if account == nil {
      account = model.makeAndSaveAccount(
        type: .gmail,
        address: profile.email, userId: user.userID ?? "",
        firstName: profile.givenName, lastName: profile.familyName,
        accessToken: auth.accessToken,
        accessTokenExpiration: auth.accessTokenExpirationDate,
        refreshToken: auth.refreshToken
      )
    } else {
      account!.accessToken = auth.accessToken
      model.save()
    }
    
    account!.loggedIn = true
  }
  
//  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
//    print("\(user.profile.email ?? "unknown") logged out")
//    model.accounts[user.profile.email]?.loggedIn = false
//  }
  
}

//
//  AccountController.swift
//  psymail
//
//  Created by bubbles on 5/28/21.

import Foundation
import GoogleSignIn

class AccountController: NSObject, GIDSignInDelegate {
  static let shared = AccountController()
  
  @Published private(set) var username: String?
  @Published private(set) var oAuthToken: String?
  @Published private(set) var loggedIn: Bool = false
  
  private override init() {
    super.init()
    
    GIDSignIn.sharedInstance().clientID = "941559531688-m6ve00j5ofshqf5ksfqng92ga7kbkbb6.apps.googleusercontent.com"
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().scopes = [
      "https://mail.google.com/"
    ]
  }
  
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    if let error = error {
      if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
        print("The user has not signed in before or they have since signed out.")
      } else {
        print("\(error.localizedDescription)")
      }
      return
    }

    username = user.profile.email
    oAuthToken = user.authentication.accessToken
    loggedIn = true
  }
  
  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    loggedIn = false
  }
  
  func restoreSignIn() {
    GIDSignIn.sharedInstance()?.restorePreviousSignIn()
  }
  
}

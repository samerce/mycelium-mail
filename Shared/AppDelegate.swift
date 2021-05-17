//
//  AppDelegate.swift
//  psymail
//
//  Created by bubbles on 5/17/21.
//

import Foundation
import UIKit
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate {
  
  @available(iOS 9.0, *)
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    return GIDSignIn.sharedInstance().handle(url)
  }
  
}

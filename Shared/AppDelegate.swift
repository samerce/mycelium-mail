import Foundation
import UIKit
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate {
  
  @available(iOS 9.0, *)
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    return AccountController.shared.handleGoogleUrl(url)
  }
  
}

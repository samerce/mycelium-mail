import Foundation
import UIKit
import SwiftUI


class NavController: ObservableObject {
  static let shared = NavController()
  
  let sheetCtrl = AppSheetController.shared
  
  var navController: UINavigationController?
  
  func goBack(withSheet sheet: AppSheet? = nil) {
    navController?.popViewController(animated: true)
    if let sheet = sheet {
      sheetCtrl.sheet = sheet
    }
  }
  
  private init() { }
  
}

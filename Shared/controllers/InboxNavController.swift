import Foundation
import UIKit
import SwiftUI


private let mailCtrl = MailController.shared
private let bundleCtrl = BundleController.shared


class InboxNavController: ObservableObject {
  static let shared = InboxNavController()
  
  let sheetCtrl = SheetController.shared
  
  var navController: UINavigationController?
  var scrollProxy: ScrollViewProxy?
  var goToPage: ((Int, Bool) -> Void)?
  
  func goBack(withSheet sheet: AppSheet? = nil) {
    navController?.popViewController(animated: true)
    if let sheet = sheet {
      sheetCtrl.sheet = sheet
    }
  }
  
  func onBundleSelected(_ bundle: EmailBundle) {
    let bundleAlreadySelected = bundleCtrl.selectedBundle == bundle
    bundleCtrl.selectedBundle = bundle
    scrollToTop(animated: bundleAlreadySelected)
  }
  
  private func scrollToTop(animated: Bool = true) {
    guard let firstThread = mailCtrl.threadsInSelectedBundle.first
    else { return }
    
    switch bundleCtrl.selectedBundle.layout {
      case .list:
        let scroll = { self.scrollProxy?.scrollTo(firstThread.objectID) }
        if animated {
          withAnimation(.easeOut) { scroll() }
        } else {
          scroll()
        }
      case .page:
        goToPage?(0, animated)
    }
  }
  
  private init() { }
  
}

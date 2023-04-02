import Foundation
import SwiftUI


private let mailCtrl = MailController.shared


struct MoveToBundleMenu: View {
  var thread: EmailThread
  var onMove: (() -> Void)?
  
  @ObservedObject var bundleCtrl = BundleController.shared
  @ObservedObject var sheetCtrl = SheetController.shared
  @ObservedObject var alertCtrl = AlertController.shared
  
  var bundles: [EmailBundle] { bundleCtrl.bundles }
  var selectedBundle: EmailBundle { bundleCtrl.selectedBundle }
  
  var body: some View {
    Group {
      Text("move to bundle")
      
      ForEach(bundles, id: \.objectID) { bundle in
        buttonForBundle(bundle)
      }
      
      Divider()
      
      Button {
        withAnimation {
          bundleCtrl.threadToMoveToNewBundle = thread
          sheetCtrl.sheet = .createBundle
        }
      } label: {
        Text("new bundle")
        SystemImage(name: "plus", size: 12)
      }
    }
  }
  
  func buttonForBundle(_ bundle: EmailBundle) -> some View {
    Button {
      alertCtrl.show(message: "moved to \(bundle.name)", icon: bundle.icon, delay: 0.54, actionLabel: "EDIT") {
        alertCtrl.hide()
        sheetCtrl.showSheet(.bundleSettings, bundle)
      }
      
      self.onMove?()
      mailCtrl.moveThread(thread, toBundle: bundle)
    } label: {
      Text(bundle.name)
      SystemImage(name: bundle.icon, size: 12)
    }
  }
  
}

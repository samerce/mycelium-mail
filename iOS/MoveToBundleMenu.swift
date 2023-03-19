import Foundation
import SwiftUI


struct MoveToBundleMenu: View {
  var thread: EmailThread
  var onMove: (() -> Void)?
  
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var alertCtrl = AppAlertController.shared
  
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
      alertCtrl.show(message: "moved to \(bundle.name)", icon: bundle.icon, delay: 0.54, action: {
        alertCtrl.hide()
        sheetCtrl.sheet = .bundleSettings
      }, actionLabel: "EDIT")
      
      withAnimation {
        let _ = Task {
          do {
            self.onMove?()
            try await MailController.shared.moveThread(thread, fromBundle: selectedBundle, toBundle: bundle)
          }
          catch {
            alertCtrl.show(message: "failed to move message", icon: "xmark", delay: 1)
          }
        }
      }
    } label: {
      Text(bundle.name)
      SystemImage(name: bundle.icon, size: 12)
    }
  }
  
}

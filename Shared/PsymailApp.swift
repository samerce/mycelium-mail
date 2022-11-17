import Foundation
import SwiftUI
import CoreData

@main
struct PsymailApp: App {
  let persistenceCtrl = PersistenceController.shared
  
  @Environment(\.scenePhase) var scenePhase
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceCtrl.container.viewContext)
        .onOpenURL { url in
            AccountController.shared.handleGoogleUrl(url)
        }
    }
    .commands {
      SidebarCommands()
    }
    .onChange(of: scenePhase) { phase in
      print(phase)
      persistenceCtrl.save()
      
      if phase == .active {
        AccountController.shared.restoreSignIn()
      }
    }
  }
  
}

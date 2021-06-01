import Foundation
import SwiftUI
import CoreData

@main
struct PsymailApp: App {
  let persistenceCtrl = PersistenceController.shared
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceCtrl.container.viewContext)
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

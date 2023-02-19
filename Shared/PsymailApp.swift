import Foundation
import SwiftUI
import CoreData

@main
struct PsymailApp: App {
  @Environment(\.scenePhase) var scenePhase
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .onOpenURL { url in
          AccountController.shared.handleGoogleUrl(url)
        }
    }
    .commands {
      SidebarCommands()
    }
    .onChange(of: scenePhase) { phase in
      print(phase)
      
      if phase == .active {
        AccountController.shared.restoreSignIn()
      }
    }
  }
  
}

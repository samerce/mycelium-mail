import Foundation
import SwiftUI
import CoreData

@main
struct PsymailApp: App {
  @Environment(\.scenePhase) var scenePhase
  @StateObject var viewModel = ViewModel()
  @StateObject var appAlertViewModel = AppAlertViewModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(viewModel)
        .environmentObject(appAlertViewModel)
        .onOpenURL { url in
          AccountController.shared.handleGoogleUrl(url)
        }
        .tint(.psyAccent)
    }
    .commands {
      SidebarCommands()
    }
    .onChange(of: scenePhase) { phase in
      print(phase)
      
      if phase == .active {
        AccountController.shared.restoreSignIn()
      } else if phase == .background {
        PersistenceController.shared.save()
      }
    }
  }
  
}

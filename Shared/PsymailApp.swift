//
//  mushroom_mailApp.swift
//  Shared
//
//  Created by bubbles on 4/24/21.
//

import SwiftUI
import CoreData

@main
struct PsymailApp: App {
  let persistenceController = PersistenceController.shared
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
//  @StateObject private var mailCtrl = MailController.shared
//  @StateObject private var store = Store()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
//        .environmentObject(mailCtrl)
//        .environmentObject(store)
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in
//          AccountController.shared.restoreSignIn()
        }
    }
    .commands {
      SidebarCommands()
    }
    .onChange(of: scenePhase) { _ in
      persistenceController.save()
    }
  }
  
}

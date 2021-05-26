//
//  mushroom_mailApp.swift
//  Shared
//
//  Created by bubbles on 4/24/21.
//

import SwiftUI
import CoreData
import GoogleSignIn

@main
struct PsymailApp: App {
  let persistenceController = PersistenceController.shared
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  @StateObject private var model = MailModel()
  //    @StateObject private var store = Store()
  
  @State private var didAppear = false
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .environmentObject(model)
        .onAppear {
          if didAppear { return }
          didAppear = true
          GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        }
      //                .environmentObject(store)
    }
    .commands {
      SidebarCommands()
    }.onChange(of: scenePhase) { _ in
      persistenceController.save()
    }
  }
  
}

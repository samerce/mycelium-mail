//
//  mushroom_mailApp.swift
//  Shared
//
//  Created by bubbles on 4/24/21.
//

import SwiftUI

@main
struct MushroomMailApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var model = MailModel()
//    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(model)
//                .environmentObject(store)
        }
        .commands {
            SidebarCommands()
        }
    }
}

//
//  mushroom_mailApp.swift
//  Shared
//
//  Created by bubbles on 4/24/21.
//

import SwiftUI

@main
struct mushroom_mailApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

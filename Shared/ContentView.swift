//
//  ContentView.swift
//  Shared
//
//  Created by bubbles on 4/24/21.
//

import SwiftUI
import CoreData
import Postal

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var model: MailModel
    
    private let tabs = ["newsletters", "politics", "marketing", "other"]
    @State private var selectedTab = 0

    var body: some View {
        List {
            let messages = model.sortedEmails[self.tabs[self.selectedTab]]!
            ForEach(messages, id: \.uid) { msg in
                let sender = msg.header?.from[0]
                let subject = msg.header?.subject
                
                VStack(alignment: .leading) {
                    Text(sender?.displayName ?? "Unknown")
                    Text(subject ?? "---")
                }
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                
                Picker("", selection: $selectedTab) {
                    ForEach(tabs.indices) { i in
                        Text(self.tabs[i]).tag(i)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 8)
//                Spacer()
            }
        }
    }

//    private func addItem() {
//        withAnimation {
//            let newItem = Item(context: viewContext)
//            newItem.timestamp = Date()
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            offsets.map { items[$0] }.forEach(viewContext.delete)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

import SwiftUI
import CoreData
import Postal
import UIKit
import DynamicOverlay

enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

let tabs = ["newsletters", "politics", "marketing", "other"]

struct AppCompactView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var model: MailModel
  
  @State var notch: Notch = .min
  @State var isEditing = false
  @State var translationProgress = 0.0
  @State var selectedTab = 0
  
  var body: some View {
    background
      .dynamicOverlay(overlay)
      .dynamicOverlayBehavior(behavior)
      .ignoresSafeArea()
  }
  
  private var background: some View {
    ZStack {
      NavigationView {
        List {
          let messages = model.sortedEmails[tabs[selectedTab]]!
          ForEach(messages, id: \.uid) { msg in
            let sender = msg.header?.from[0].displayName ?? "Unknown"
            let subject = msg.header?.subject ?? "---"
            
            VStack(alignment: .leading) {
              Text(sender).padding(.bottom, 6)
              Text(subject)
            }.padding(.vertical, 12)
          }
        }
        .navigationBarTitle("") // oddly required to hide the bar
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
      }
      
      backdropView.opacity(translationProgress)
    }
    .ignoresSafeArea()
  }
  
  private var backdropView: some View {
    Color.black.opacity(0.3)
  }
  
  private var overlay: some View {
    InboxDrawerView(translationProgress: $translationProgress) { event in
      switch event {
      case .didTapTab:
        isEditing = true
        withAnimation { notch = .max }
      }
    }
    .drivingScrollView()
    .frame(maxHeight: .infinity)
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.98)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .fractional(0.18)
      }
    }
    .disable(.min, isEditing)
    .notchChange($notch)
    .onTranslation { translation in
      translationProgress = translation.progress
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

struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      .environmentObject(MailModel())
  }
}

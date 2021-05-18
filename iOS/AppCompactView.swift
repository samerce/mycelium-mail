import SwiftUI
import CoreData
import Postal
import UIKit
import DynamicOverlay

enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

let categories = ["marketing", "newsletters", "other", "politics"]
let tabs = ["DMs", "events", "digests", "commerce", "society"]

struct AppCompactView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var model: MailModel
  
  @State var notch: Notch = .min
  @State var isEditing = false
  @State var translationProgress = 0.0
  @State var selectedTab = 0
  
  var body: some View {
    ZStack {
      NavigationView {
        ScrollView {
          LazyVStack {
            let messages = model.sortedEmails[categories[selectedTab]]!
            ForEach(messages, id: \.uid) { msg in
              getListRow(msg)
            }
            .onDelete { _ in print("deleted") }
          }
        }
        .padding(0)
        .navigationBarTitle(tabs[selectedTab])
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
          leading: Image(systemName: "lasso.sparkles")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.yellow)
            .frame(width: 27, height: 27),
          trailing: EditButton()
        )
        
        backdropView.opacity(translationProgress)
      }
      .dynamicOverlay(overlay)
      .dynamicOverlayBehavior(behavior)
    }
    .ignoresSafeArea()
  }
  
  private func getListRow(_ msg: FetchResult) -> some View {
    let sender = msg.header?.from[0].displayName ?? "Unknown"
    let subject = msg.header?.subject ?? "---"
    let date = msg.internalDate?.description ?? ""
    return ZStack {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .lastTextBaseline) {
          Text(sender).font(.system(size: 16, weight: .bold, design: .default))
          Spacer()
          Text(date).font(.system(size: 12, weight: .light, design: .default))
          Image(systemName: "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.gray)
            .frame(width: 12, height: 12)
        }
        Text(subject)
      }
      .frame(maxWidth: .infinity)
      .padding(6)
      
      NavigationLink(destination: MessageView(msg.uid)) {
        EmptyView()
      }
      .hidden()
//      .listRowBackground(getRowBackground(msg))
    }
    .background(getRowBackground(msg))
    .listRowInsets(EdgeInsets())
  }
  
  private func getRowBackground(_ msg: FetchResult) -> some View {
    var background: AnyView
    if msg.flags.contains(.seen) {
      background = AnyView(Rectangle())
    } else {
      let rect = RainbowGlowBorder()
      background = AnyView(rect)
    }
    return background.padding(4)
  }
  
  private var backdropView: some View {
    Color.black.opacity(0.3)
  }
  
  private var overlay: some View {
    GeometryReader { geometry in
      InboxDrawerView(selectedTab: $selectedTab, translationProgress: $translationProgress) { event in
        switch event {
        case .didTapTab:
          isEditing = true
          withAnimation { notch = .max }
        }
      }
      .ignoresSafeArea()
      .frame(minHeight: geometry.size.height * 0.9)
    }
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.92)
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
  
  private func showAbout() {
    
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
    let model = MailModel()
    model.signIn()
    return AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      .environmentObject(model)
  }
}

import SwiftUI
import CoreData
import MailCore
import UIKit
import DynamicOverlay

enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

let tabs = [
  "DMs", "events", "digests", "commerce", "society",
  "marketing", "news", "notifications", "everything"
]
let oneDay = 24.0 * 3600
let twoDays = 48.0 * 3600
let oneWeek = 24.0 * 7 * 3600

struct AppCompactView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var model: MailModel
  
  @State var notch: Notch = .min
  @State var isEditing = false
  @State var translationProgress = 0.0
  @State var selectedTab = 2
  @State var selectedRow:UInt32? = 0
  
  var body: some View {
    NavigationView {
      ZStack {
          ScrollView {
            LazyVStack {
              let emails = model.sortedEmails[tabs[selectedTab]] ?? []
              ForEach(emails, id: \.uid) { email in
                let row = getListRow(email)
                if email.message.flags.contains(.seen) {
                  row
                } else {
                  row
                    .overlay(RainbowGlowBorder().opacity(0.98))
                    .background(VisualEffectBlur(blurStyle: .prominent))
                    .cornerRadius(12)
                }
              }
              .onDelete { _ in print("deleted") }
            }
            .padding(.horizontal, 6)
            
            Spacer().frame(height: 138)
          }
          .padding(.horizontal, -2)
      
        backdropView.opacity(translationProgress)
      }
      .dynamicOverlay(overlay)
      .dynamicOverlayBehavior(behavior)
      .ignoresSafeArea()
      .navigationBarTitle(tabs[selectedTab])
      .navigationBarItems(
        leading:
            Image(systemName: "mail")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .font(.system(size: 27, weight: .light, design: .default))
              .frame(width: 27, height: 27)
          .foregroundColor(.pink),
        trailing:
            EditButton()
              .font(.system(size: 17, weight: .regular, design: .default))
          .foregroundColor(.pink)
      )
    }
  }
  
  private func getListRow(_ email: Email) -> some View {
    let header = email.message.header
    let sender = header?.from.displayName ?? "Unknown"
    let subject = header?.subject ?? "---"
    return ZStack {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .lastTextBaseline) {
          Text(sender)
            .font(.system(size: 15, weight: .bold, design: .default))
            .lineLimit(1)
          Spacer()
          Text(formattedDateFor(email))
            .font(.system(size: 12, weight: .light, design: .default))
            .foregroundColor(Color.secondary)
            Image(systemName: "chevron.right")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.gray)
              .frame(width: 12, height: 12)
              .offset(x: 0, y: 1)
        }
        Text(subject)
          .font(.system(size: 15, weight: .light, design: .default))
          .lineLimit(2)
      }
      .foregroundColor(Color.primary)
      .padding(.horizontal, 6)
      .padding(.vertical, 12)
      
      NavigationLink(
        destination: EmailDetailView(email: email), tag: email.uid, selection: $selectedRow
      ) {
        EmptyView()
      }
    }
    .listRowInsets(EdgeInsets())
    .padding(.horizontal, 6)
    .contentShape(Rectangle())
    .onTapGesture {
      selectedRow = email.uid
    }
  }
  
  private func formattedDateFor(_ email: Email) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm a"
    let date = email.message.header.receivedDate
    let timeSinceMessage = date?.distance(to: Date()) ?? Double.infinity
    if  timeSinceMessage > oneDay && timeSinceMessage < twoDays   {
      dateFormatter.doesRelativeDateFormatting = true
      dateFormatter.dateStyle = .short
      dateFormatter.timeStyle = .short
    } else if timeSinceMessage > twoDays && timeSinceMessage < oneWeek {
      dateFormatter.dateFormat = "E h:mm a"
    } else if timeSinceMessage > oneWeek {
      dateFormatter.dateFormat = "M/d/yy"
    }
    return (date != nil) ? dateFormatter.string(from: date!) : ""
  }
  
  private var backdropView: some View {
    Color.black.opacity(0.54)
  }
  
  private var overlay: some View {
    InboxDrawerView(selectedTab: $selectedTab, translationProgress: $translationProgress) { event in
      switch event {
      case .didTapTab:
        isEditing = true
        withAnimation { notch = .max }
      }
    }
    .onChange(of: selectedTab) { _ in
      withAnimation {
        notch = .min
      }
    }
    .zIndex(10)
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.82)
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
  
}

struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    let model = MailModel()
    model.signIn()
    return AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      .environmentObject(model)
  }
}

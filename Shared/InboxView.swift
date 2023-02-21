import SwiftUI
import SwiftUIKit
import UIKit
import CoreData


private let DefaultBundle = Bundles[0]


struct InboxView: View {
  @StateObject private var mailCtrl = MailController.shared
  @State private var bundle = DefaultBundle
  @State private var selectedEmails: Set<Email> = []
  @State private var sheetPresented = true
  @State private var appSheetMode: AppSheetMode = .inboxTools
  @State private var editMode: EditMode = .inactive
  @State private var shouldScrollToTop: Bool = false
  @StateObject private var appAlert: AppAlert = AppAlert()
  
  @FetchRequest(fetchRequest: Email.fetchRequestForBundle(DefaultBundle), animation: .easeInOut)
  private var emailResults: FetchedResults<Email>
  
  // MARK: - VIEW
  
  var body: some View {
    NavigationSplitView {
      EmailList
    } detail: {
      if selectedEmails.isEmpty {
        Text("no message selected")
      } else {
        EmailDetailView(email: selectedEmails.first!)
      }
    }
    .onChange(of: bundle) { _bundle in
      emailResults.nsPredicate = Email.predicateForBundle(_bundle)
    }
    .onChange(of: selectedEmails) { _ in
      if editMode.isEditing { return }
      withAnimation {
        switch (selectedEmails.isEmpty) {
          case true: appSheetMode = .inboxTools
          case false: appSheetMode = .emailTools
        }
      }
    }
    .sheet(isPresented: $sheetPresented) {
      AppSheetView(mode: $appSheetMode, bundle: $bundle)
    }
    .environmentObject(appAlert)
    .overlay(alignment: .center) {
      AlertOverlay
    }
  }
  
  private var AlertOverlay: some View {
    VStack(alignment: .center) {
      if let icon = appAlert.icon {
        SystemImage(icon, size: 69, color: .white.opacity(0.69))
      }
      Text(appAlert.message ?? "")
        .font(.system(size: 15, weight: .medium))
        .padding(12)
    }
    .animation(.easeInOut, value: appAlert)
    .foregroundColor(.white.opacity(0.69))
    .frame(width: 200, height: 200)
    .background(
      OverlayBackgroundView(blurStyle: .systemChromeMaterial)
        .shadow(color: .black.opacity(0.54), radius: 18)
    )
    .border(.white.opacity(0.12), width: 0.27)
    .cornerRadius(12)
    .visible(if: appAlert.message != nil || appAlert.icon != nil)
  }
  
}

// MARK: - EmailList

extension InboxView {
  private var EmailList: some View {
    ScrollViewReader { scrollProxy in
      List(emailResults, id: \.self, selection: $selectedEmails) {
        EmailListRow(email: $0)
          .id($0.objectID)
      }
      .listStyle(.plain)
      .listRowInsets(.none)
      .navigationBarTitleDisplayMode(.inline)
      .environment(\.editMode, $editMode)
      .toolbar(content: ToolbarContent)
      .refreshable {
        try? await mailCtrl.fetchLatest()
      }
      .safeAreaInset(edge: .bottom) {
        Spacer().frame(height: appSheetDetents.min)
      }
      .onChange(of: emailResults.nsPredicate) { _ in
        shouldScrollToTop = true
      }
      .onChange(of: emailResults.first) { _ in
        if shouldScrollToTop {
          shouldScrollToTop = false
          scrollProxy.scrollTo(emailResults.first?.objectID)
        }
      }
    }
  }
  
  @ToolbarContentBuilder
  private func ToolbarContent() -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button(action: {}) {
        SystemImage("rectangle.grid.1x2", size: 20)
      }
    }
    ToolbarItem(placement: .principal) {
      Text(bundle == "everything" ? "inbox" : bundle)
        .font(.system(size: 27, weight: .black))
        .padding(.bottom, 6)
    }
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        withAnimation {
          editMode = editMode.isEditing ? .inactive : .active
        }
      } label: {
        Text(editMode.isEditing ? "Done" : "Edit")
          .animation(nil)
          .foregroundColor(.psyAccent)
      }
    }
  }
}


struct EmailListView_Previews: PreviewProvider {
  static var previews: some View {
    InboxView()
  }
}

private func SystemImage(_ name: String, size: CGFloat, color: Color = .psyAccent) -> some View {
  Image(systemName: name)
    .resizable()
    .aspectRatio(contentMode: .fit)
    .font(.system(size: size, weight: .light, design: .default))
    .foregroundColor(color)
    .frame(width: size, height: size)
    .contentShape(Rectangle())
    .clipped()
}

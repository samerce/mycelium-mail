import SwiftUI
import SwiftUIKit
import UIKit
import CoreData


struct InboxView: View {
  @EnvironmentObject var viewModel: ViewModel
  @StateObject var mailCtrl = MailController.shared
  
  @State var sheetPresented = true
  @State var selectedEmails: Set<Email> = []
  @State var editMode: EditMode = .inactive
  
  var selectedBundle: EmailBundle { viewModel.selectedBundle }
  var emails: [Email] { viewModel.emailsInSelectedBundle }
  
  
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
    .sheet(isPresented: $sheetPresented) {
      AppSheetView()
    }
    .onChange(of: selectedEmails) { _ in
      if editMode.isEditing { return }
      
      withAnimation {
        switch (selectedEmails.isEmpty) {
          case true: viewModel.appSheetMode = .inboxTools
          case false: viewModel.appSheetMode = .emailTools
        }
      }
    }
  }
  
}

// MARK: - EmailList

extension InboxView {
  
  var EmailList: some View {
    ScrollViewReader { scrollProxy in
      List(emails, id: \.self, selection: $selectedEmails) {
        EmailListRow(email: $0)
          .id($0.objectID)
      }
      .animation(.default, value: emails)
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
      .onChange(of: selectedBundle) { _ in
        scrollProxy.scrollTo(emails.first?.objectID)
      }
      .introspectNavigationController {
        if viewModel.navController == nil {
          viewModel.navController = $0
        }
      }
    }
  }
  
  @ToolbarContentBuilder
  private func ToolbarContent() -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button(action: {}) {
        SystemImage(name: "rectangle.grid.1x2", size: 20)
      }
    }
    ToolbarItem(placement: .principal) {
      Text(selectedBundle.name)
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

import SwiftUI
import SwiftUIKit
import UIKit
import CoreData


struct InboxView: View {
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var mailCtrl = MailController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var navCtrl = NavController.shared
  
  @State var sheetPresented = true
  @State var selectedThreads: Set<EmailThread> = []
  @State var editMode: EditMode = .inactive
  
  var selectedBundle: EmailBundle { bundleCtrl.selectedBundle }
  var threads: [EmailThread] { mailCtrl.threadsInSelectedBundle }
  
  // MARK: - VIEW
  
  var body: some View {
    NavigationSplitView {
      EmailList
    } detail: {
      if selectedThreads.isEmpty {
        Text("no message selected")
      } else {
        EmailDetailView(thread: selectedThreads.first!)
      }
    }
    .sheet(isPresented: $sheetPresented) {
      AppSheetView()
    }
    .onChange(of: selectedThreads) { _ in
      if editMode.isEditing { return }
      
      withAnimation {
        switch (selectedThreads.isEmpty) {
          case true: sheetCtrl.sheet = .inbox
          case false: sheetCtrl.sheet = .emailDetail
        }
      }
    }
  }
  
}

// MARK: - EmailList

extension InboxView {
  
  var EmailList: some View {
    ScrollViewReader { scrollProxy in
      List(threads, id: \.self, selection: $selectedThreads) {
        EmailListRow(thread: $0)
          .id($0.objectID)
      }
      .animation(.default, value: threads)
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
        if let firstThread = threads.first {
          scrollProxy.scrollTo(firstThread.objectID)
        }
      }
      .onChange(of: selectedThreads) { _ in
        mailCtrl.selectedThreads = selectedThreads
      }
      .introspectNavigationController {
        if navCtrl.navController == nil {
          navCtrl.navController = $0
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

import SwiftUI
import SwiftUIKit
import UIKit
import CoreData


struct InboxView: View {
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var mailCtrl = MailController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var navCtrl = NavController.shared
  
  @State var selectedThreads: Set<EmailThread> = []
  @State var editMode: EditMode = .inactive
  @State var threadPageIndex: Int = 0
  @State var scrollProxy: ScrollViewProxy?
  
  var selectedBundle: EmailBundle { bundleCtrl.selectedBundle }
  var threads: [EmailThread] { mailCtrl.threadsInSelectedBundle }
  var selectedThread: EmailThread? {
    switch selectedBundle.layout {
      case .page: return threads.count > 0 ? threads[threadPageIndex] : nil
      case .list: return selectedThreads.first
    }
  }
  
  // MARK: - VIEW
  
  var body: some View {
    NavigationSplitView {
      ThreadList
    } detail: {
      ThreadDetails
    }
    .onChange(of: selectedThreads) { _ in
      if editMode.isEditing { return }
      
      withAnimation {
        switch (selectedThreads.isEmpty) {
          case true: sheetCtrl.sheet = .inbox
          case false: sheetCtrl.sheet = .emailThread
        }
      }
    }
  }
  
  var ThreadList: some View {
    ZStack {
      switch selectedBundle.layout {
        case .page: PageList
        case .list: InboxList
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .environment(\.editMode, $editMode)
    .toolbar(content: ToolbarContent)
    .safeAreaInset(edge: .bottom) {
      Spacer().height(appSheetDetents.min)
    }
    .introspectNavigationController {
      if navCtrl.navController == nil {
        navCtrl.navController = $0
      }
    }
    .refreshable {
      try? await mailCtrl.fetchLatest()
    }
    .onChange(of: selectedThreads) { _ in
      mailCtrl.selectedThreads = selectedThreads
    }
  }
  
  @ViewBuilder
  var ThreadDetails: some View {
    if let thread = selectedThread {
      EmailThreadView(thread: thread)
    } else {
      Text("no message selected")
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

// MARK: - InboxList

extension InboxView {
  
  var InboxList: some View {
    List(threads, id: \.self, selection: $selectedThreads) {
      InboxListRow(thread: $0)
        .id($0.objectID)
    }
    .animation(.default, value: threads)
    .listStyle(.plain)
    .onChange(of: selectedBundle) { _ in
      if let firstThread = threads.first {
        scrollProxy?.scrollTo(firstThread.objectID)
      }
    }
    .scrollProxy($scrollProxy)
  }
  
}

// MARK: - PageList

extension InboxView {
  
  @ViewBuilder
  var PageList: some View {
    if threads.count == 0 {
      EmptyView()
    } else {
      PageView(selection: $threadPageIndex, axis: .vertical, spacing: 0, prev: prev, next: next) { threadIndex in
        NavigationLink {
          ThreadDetails
        } label: {
          ThreadPage(thread: threads[threadIndex])
        }
      }
      .ignoresSafeArea()
      .onChange(of: selectedBundle) { _ in
        threadPageIndex = 0
      }
      .scrollProxy($scrollProxy)
    }
  }
  
  func prev(_ threadIndex: Int) -> Int? {
    if threadIndex == 0 {
      return nil
    } else {
      return threadIndex - 1
    }
  }
  
  func next(_ threadIndex: Int) -> Int? {
    if threadIndex == threads.count - 1 {
      return nil
    } else {
      return threadIndex + 1
    }
  }
  
}


struct EmailListView_Previews: PreviewProvider {
  static var previews: some View {
    InboxView()
  }
}

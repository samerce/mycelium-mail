import SwiftUI
import SwiftUIKit
import UIKit
import CoreData


struct InboxView: View {
  @StateObject private var mailCtrl = MailController.shared
  @State private var bundle = Bundles[0]
  @State private var emailIds: Set<NSManagedObjectID> = []
  @State private var sheetPresented = true
  @State private var view = "inbox"
  @State private var emails: [Email] = []
  
//  @FetchRequest(fetchRequest: Email.fetchRequestForBundle())
//  private var emails: FetchedResults<Email>
  
  // MARK: -
  
  var body: some View {
    NavigationSplitView {
      EmailList
    } detail: {
      if emailIds.isEmpty {
        Text("no message selected")
      } else {
        EmailDetailView(id: emailIds.first!)
          .onAppear() { view = "email.detail" }
          .onDisappear() { view = "inbox" }
      }
    }
    .sheet(isPresented: $sheetPresented) {
      AppSheetView(view: $view, bundle: $bundle)
    }
    .onChange(of: bundle) { _bundle in
//      emails.nsPredicate = Email.predicateForBundle(_bundle)
      emails = mailCtrl.model.getEmails(for: bundle)
    }
  }
  
  private var EmailList: some View {
    List(emails, id: \.objectID, selection: $emailIds) {
      EmailListRow(email: $0)
    }
    .listStyle(.plain)
    .listRowInsets(.none)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { mailCtrl.fetchLatest() }
    .toolbar(content: toolbarContent )
    .onChange(of: bundle) { _bundle in
//      scrollProxy.scrollTo(emails.first?.uid)
    }
    .safeAreaInset(edge: .bottom) {
      Spacer().frame(height: appSheetDetents.min)
    }
  }
  
  @ToolbarContentBuilder
  private func toolbarContent() -> some ToolbarContent {
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
      Button(action: {}) {
        Text("Edit")
          .foregroundColor(.psyAccent)
      }
    }
  }
  
  private func SystemImage(_ name: String, size: CGFloat) -> some View {
    Image(systemName: name)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .font(.system(size: size, weight: .light, design: .default))
      .foregroundColor(.psyAccent)
      .frame(width: size, height: size)
      .contentShape(Rectangle())
      .clipped()
  }
  
}

// MARK: -

struct EmailListView_Previews: PreviewProvider {
  static var previews: some View {
    InboxView()
  }
}

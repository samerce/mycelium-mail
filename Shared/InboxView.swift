import SwiftUI
import SwiftUIKit


struct InboxView: View {
  @StateObject private var mailCtrl = MailController.shared
  @State private var bundle: String = Bundles[0]
  @State private var translationProgress = 0.0
  @State private var scrollOffsetY: CGFloat = 0
  @State private var emailIds: Set<Email.ID> = []
  @State private var inboxSheetPresented = true
  @State private var emailDetailSheetPresented = true
  
  @FetchRequest(fetchRequest: Email.fetchRequestForBundle())
  private var emails: FetchedResults<Email>
  
  // MARK: -
  
  var body: some View {
    NavigationSplitView {
      EmailList
        .onAppear() { inboxSheetPresented = true }
        .onDisappear() { inboxSheetPresented = false }
    } detail: {
      EmailDetailView(emailId: emailIds.first)
        .onAppear() { emailDetailSheetPresented = true }
        .onDisappear() { emailDetailSheetPresented = false }
    }
    .sheet(isPresented: $inboxSheetPresented) { InboxSheet }
    .sheet(isPresented: $emailDetailSheetPresented) { EmailDetailSheet }
  }
  
  private var EmailList: some View {
    ScrollViewReader { scrollProxy in
      List(emails, id: \.uid, selection: $emailIds) {
        EmailListRow(email: $0)
          .if($0 == emails.last) { row in
            row.padding(.bottom, inboxSheetDetents.min)
          }
      }
      .listStyle(.plain)
      .listRowInsets(.none)
      .navigationBarTitleDisplayMode(.inline)
      .refreshable { mailCtrl.fetchLatest() }
      .toolbar {
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
      .onChange(of: bundle) { _bundle in
        emails.nsPredicate = Email.predicateForBundle(_bundle)
        scrollProxy.scrollTo(emails.first?.uid)
      }
    }
  }
  
  private var TitleToolbar: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      HStack {
        Button(action: {}) {
          SystemImage("rectangle.grid.1x2", size: 20)
        }

        Spacer()

        Text(bundle == "everything" ? "inbox" : bundle)
          .font(.system(size: 27, weight: .black))
          .padding(.bottom, 6)

        Spacer()

        Button(action: {}) {
          Text("Edit")
            .foregroundColor(.psyAccent)
        }
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
  
  private var InboxSheet: some View {
    InboxSheetView(bundle: $bundle, translationProgress: $translationProgress)
      .interactiveDismissDisabled()
      .presentationDetents(
        undimmed: [
          .height(inboxSheetDetents.min),
          .height(inboxSheetDetents.mid),
          .height(inboxSheetDetents.max)
        ]
      )
//      .onChange(of: bundle) { _ in
//        withAnimation {
//          notch = .min
//        }
//      }
  }
  
  private var EmailDetailSheet: some View {
    EmailToolsSheetView()
      .interactiveDismissDisabled()
      .presentationDetents(
        undimmed: [
          .height(inboxSheetDetents.min),
          .height(inboxSheetDetents.mid),
          .height(inboxSheetDetents.max)
        ]
      )
  }
  
}

// MARK: -

struct EmailListView_Previews: PreviewProvider {
  static var previews: some View {
    InboxView()
  }
}

struct ViewOffsetKey: PreferenceKey {
  typealias Value = CGFloat
  static var defaultValue = CGFloat.zero
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value += nextValue()
  }
}


func memo<Input: Hashable, Output>(_ function: @escaping (Input) -> Output) -> (Input) -> Output {
    // our item cache
    var storage = [Input: Output]()

    // send back a new closure that does our calculation
    return { input in
        if let cached = storage[input] {
            return cached
        }

        let result = function(input)
        storage[input] = result
        return result
    }
}

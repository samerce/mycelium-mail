import SwiftUI
import SwiftUIKit

private enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

private var mailCtrl = MailController.shared

private var cTitleToolbarSize = 70.0
private var cMinDrawerSize = 90.0

struct InboxView: View {
  @StateObject private var model = mailCtrl.model
  @State private var notch: Notch = .min
  @State private var translationProgress = 0.0
  @State private var bundle = "everything"
  @State private var scrollOffsetY: CGFloat = 0
  @State private var safeAreaBackdropOpacity: Double = 0
  @State private var emailIds: Set<Email.ID> = []
  @Namespace var headerId
  @State private var drawerPresented = true
  
  private var emails: [Email] { model.emails[bundle]! }
  private var zippedEmails: Array<EnumeratedSequence<[Email]>.Element> {
    Array(zip(emails.indices, emails))
  }
  
  private var getMaxDetent: (CGFloat) -> CGFloat {
    memo { screenHeight in
      screenHeight - safeAreaInsets.top
    }
  }
  
  // MARK: -
  
  var body: some View {
    NavigationSplitView {
      EmailList
        .toolbar { TitleToolbar }
        .navigationBarTitleDisplayMode(.inline)
    } detail: {
      EmailDetailView(emailId: emailIds.first)
        .navigationBarBackButtonHidden()
    }
    .padding(.zero)
    .sheet(isPresented: $drawerPresented) { Sheet }
  }
  
  private var EmailList: some View {
//    ScrollViewReader { scrollProxy in
    
      List(emails, selection: $emailIds) {
        EmailListRow(email: $0)
          .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button { print("follow up") } label: {
              Label("follow up", systemImage: "pin")
            }
            Button { print("bundle") } label: {
              Label("bundle", systemImage: "giftcard")
            }
            Button { print("delete") } label: {
              Label("trash", systemImage: "trash")
            }
            Button { print("note") } label: {
              Label("note", systemImage: "note.text")
            }
            Button { print("notification") } label: {
              Label("notifications", systemImage: "bell")
            }
          }
          .onAppear {
            //                if index > emails.count - 9 {
            //                  mailCtrl.fetchMore(bundle)
            //                }
          }
        //            .onTapGesture { mailCtrl.selectEmail(email) }
        //          }
      }
      .listStyle(.plain)
      .listRowInsets(.none)
      .edgesIgnoringSafeArea(.bottom)
    //      .onChange(of: bundle) { _ in scrollProxy.scrollTo(headerId)}
  }
  
  private var TitleToolbar: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text(bundle)
        .font(.system(size: 27, weight: .black))
        .padding(.bottom, 6)
//        .id(headerId)
//        .background(GeometryReader {
//          Color.clear.preference(key: ViewOffsetKey.self,
//                                 value: -$0.frame(in: .global).minY)
//        })
//        .onPreferenceChange(ViewOffsetKey.self) { scrollOffsetY = $0 }
//        .listRowInsets(.init(top: 0, leading: 6, bottom: 9, trailing: 0))
//        .listRowSeparator(.hidden)
//        .frame(maxWidth: .infinity, maxHeight: 39, alignment: .center)
//        .padding(.vertical, 12)
    }
  }
  
  private var Sheet: some View {
    InboxDrawerView(bundle: $bundle, translationProgress: $translationProgress)
      .onChange(of: bundle) { _ in
        withAnimation {
          notch = .min
        }
      }
      .presentationDetents(
        undimmed: [
          .height(cMinDrawerSize),
          .fraction(0.54),
          .height(getMaxDetent(self.screenHeight))
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

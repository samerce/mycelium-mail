import SwiftUI
import DynamicOverlay

private enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

private var mailCtrl = MailController.shared

struct InboxView: View {
  @StateObject private var model = mailCtrl.model
  @State private var notch: Notch = .min
  @State private var translationProgress = 0.0
  @State private var bundle = "everything"
  @State private var scrollOffsetY: CGFloat = 0
  @State private var safeAreaBackdropOpacity: Double = 0
  @Namespace var headerId
  
  private var emails: [Email] { model.emails[bundle]! }
  private var zippedEmails: Array<EnumeratedSequence<[Email]>.Element> {
    Array(zip(emails.indices, emails))
  }
  
  var body: some View {
    EmailList
//    ZStack(alignment: .topLeading) {
//      EmailList
//      SafeAreaBackdrop
//    }
  }
  
  private var EmailList: some View {
    ScrollViewReader { scrollProxy in
      VStack(spacing: 0) {
        Header
        
        List(emails) {
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
        .onChange(of: bundle) { _ in
          scrollProxy.scrollTo(headerId)
        }
        .padding(.horizontal, 0)
        .listStyle(.plain)
        .listRowInsets(.none)
        
//        Spacer().frame(height: 120)
//          .listRowInsets(.init())
//          .listRowSeparator(.hidden)
      }
      .ignoresSafeArea()
      .padding(.top, safeAreaInsets.top)
      .padding(.bottom, safeAreaInsets.top + safeAreaInsets.bottom)
      .dynamicOverlay(Sheet)
      .dynamicOverlayBehavior(behavior)
    }
  }
  
  private var Header: some View {
    Text(bundle)
      .font(.system(size: 36, weight: .black))
      .id(headerId)
      .background(GeometryReader {
        Color.clear.preference(key: ViewOffsetKey.self,
                               value: -$0.frame(in: .global).minY)
      })
      .onPreferenceChange(ViewOffsetKey.self) { scrollOffsetY = $0 }
      .listRowInsets(.init(top: 0, leading: 6, bottom: 9, trailing: 0))
      .listRowSeparator(.hidden)
      .frame(maxWidth: .infinity, maxHeight: 39, alignment: .center)
      .padding(.vertical, 12)
  }
  
  private var SafeAreaBackdrop: some View {
    VisualEffectBlur(blurStyle: .prominent)
      .frame(maxWidth: .infinity, maxHeight: safeAreaInsets.top)
      .opacity(safeAreaBackdropOpacity)
      .onChange(of: scrollOffsetY) { _ in
        let newOpacity: Double = scrollOffsetY > -54 ? 1 : 0
        if safeAreaBackdropOpacity != newOpacity {
          withAnimation(.spring(response: 0.36)) { safeAreaBackdropOpacity = newOpacity }
        }
      }
  }
  
  private var BackdropView: some View {
    Color.black.opacity(0.54)
  }
  
  private var Sheet: some View {
    InboxDrawerView(bundle: $bundle, translationProgress: $translationProgress)
      .onChange(of: bundle) { _ in
        withAnimation {
          notch = .min
        }
      }
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .absolute(self.screenHeight - safeAreaInsets.top)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .absolute(120)
      }
    }
    .notchChange($notch)
    .onTranslation { translation in
      withAnimation(.linear(duration: 0.15)) {
        translationProgress = translation.progress
      }
    }
    .contentAdjustmentMode(.none)
  }
  
}

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

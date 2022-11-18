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
  @State private var perspective = "everything"
  @State private var scrollOffsetY: CGFloat = 0
  @State private var safeAreaBackdropOpacity: Double = 0
  @Namespace var headerId
  
  private var emails: [Email] { model.emails[perspective]! }
  private var zippedEmails: Array<EnumeratedSequence<[Email]>.Element> {
    Array(zip(emails.indices, emails))
  }
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      EmailList
      SafeAreaBackdrop
    }
  }
  
  private var Header: some View {
    Text(perspective)
      .font(.system(size: 36, weight: .black))
      .id(headerId)
      .background(GeometryReader {
        Color.clear.preference(key: ViewOffsetKey.self,
                               value: -$0.frame(in: .global).minY)
      })
      .onPreferenceChange(ViewOffsetKey.self) { scrollOffsetY = $0 }
  }
  
  private var EmailList: some View {
    ScrollViewReader { scrollProxy in
      List {
        Header
          .listRowInsets(.init(top: 0, leading: 6, bottom: 9, trailing: 0))
        
        ForEach(emails) { email in
          EmailListRow(email: email)
            .swipeActions(edge: .trailing) {
              Button { print("follow up") } label: {
                Label("follow up", systemImage: "plus.circle")
              }
              Button { print("bundle") } label: {
                Label("bundle", systemImage: "minus.circle")
              }
              Button { print("delete") } label: {
                Label("trash", systemImage: "trash")
              }
            }
//            .onTapGesture { mailCtrl.selectEmail(email) }
          //                .onAppear {
          //                  if index > emails.count - 9 {
          //                    mailCtrl.fetchMore(for: perspective)
          //                  }
          //                }
        }
        
        Spacer().frame(height: 120)
      }
      .dynamicOverlay(Sheet)
      .dynamicOverlayBehavior(behavior)
      .padding(.top, safeAreaInsets.top)
      .padding(.horizontal, 0)
      .ignoresSafeArea()
      .listStyle(.plain)
      .listRowInsets(.none)
      .onChange(of: perspective) { _ in
        scrollProxy.scrollTo(headerId)
      }
    }
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
    InboxDrawerView(perspective: $perspective, translationProgress: $translationProgress)
      .onChange(of: perspective) { _ in
        withAnimation {
          notch = .min
        }
      }
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .absolute(self.screenHeightSafe)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .absolute(88)
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

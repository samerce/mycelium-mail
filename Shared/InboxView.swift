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
      ScrollViewReader { scrollProxy in
        ScrollView {
          Text(perspective)
            .font(.system(size: 36, weight: .black))
            .padding(.top, 9)
            .id(headerId)
            .background(GeometryReader {
              Color.clear.preference(key: ViewOffsetKey.self,
                                     value: -$0.frame(in: .global).minY)
            })
            .onPreferenceChange(ViewOffsetKey.self) { scrollOffsetY = $0 }
            
          LazyVStack(spacing: 1) {
            ForEach(emails) { email in
              EmailListRow(email: email)
                .onTapGesture { mailCtrl.selectEmail(email) }
//                .onAppear {
//                  if index > emails.count - 9 {
//                    mailCtrl.fetchMore(for: perspective)
//                  }
//                }
            }
          }
          .ignoresSafeArea()
          .padding(.horizontal, 10)

          Spacer().frame(height: 138)
        }
        .dynamicOverlay(Sheet)
        .dynamicOverlayBehavior(behavior)
        .ignoresSafeArea()
        .padding(.top, safeAreaInsets.top)
        .onChange(of: perspective) { _ in
          scrollProxy.scrollTo(headerId)
        }
      }
      
      SafeAreaHeader
    }
  }
  
  private var SafeAreaHeader: some View {
    VisualEffectBlur(blurStyle: .prominent)
      .frame(maxWidth: .infinity, maxHeight: safeAreaInsets.top)
      .opacity(safeAreaBackdropOpacity)
      .onChange(of: scrollOffsetY) { _ in
        let newOpacity: Double = scrollOffsetY > -33 ? 1 : 0
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
        return .absolute(92)
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

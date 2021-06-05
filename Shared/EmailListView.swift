import SwiftUI
import DynamicOverlay

private enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

private var mailCtrl = MailController.shared

struct EmailListView: View {
  @StateObject private var model = mailCtrl.model
  @State private var notch: Notch = .min
  @State private var translationProgress = 0.0
  @State private var selectedTab = 2
  @State private var scrollViewOffsetY: CGFloat?
  @State private var safeAreaBackdropOpacity: Double = 0
  @Namespace var headerId
  
  private var perspective: String { Tabs[selectedTab] }
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      SafeAreaBackdrop
      
      ScrollViewReader { scrollProxy in
        ScrollView {
          Text(perspective)
            .font(.system(size: 36, weight: .black))
            .padding(.top, 9)
            .id(headerId)
            
          
          LazyVStack(spacing: 2) {
            ForEach(model.emails[perspective] ?? [], id: \.uuid) { email in
              EmailListRow(email: email)
                .onTapGesture { mailCtrl.selectEmail(email) }
            }
            .onDelete { _ in print("deleted") }
          }
          .ignoresSafeArea()
          .padding(.horizontal, 10)
          
          Spacer().frame(height: 138)
        }
        .dynamicOverlay(EmailListDrawer)
        .dynamicOverlayBehavior(behavior)
        .ignoresSafeArea()
        .onChange(of: selectedTab) { _ in
          scrollProxy.scrollTo(headerId)
        }
        .introspectScrollView { scrollView in
          scrollViewOffsetY = scrollView.contentOffset.y
        }
      }
    }
  }
  
  private var SafeAreaBackdrop: some View {
    VisualEffectBlur(blurStyle: .prominent)
      .frame(maxWidth: .infinity, maxHeight: safeAreaInsets.top)
      .opacity(safeAreaBackdropOpacity)
      .onChange(of: scrollViewOffsetY) { _ in
        withAnimation { safeAreaBackdropOpacity = 1 }
      }
  }
  
  private var BackdropView: some View {
    Color.black.opacity(0.54)
  }
  
  private var EmailListDrawer: some View {
    InboxDrawerView(selectedTab: $selectedTab, translationProgress: $translationProgress)
      .onChange(of: selectedTab) { _ in
        withAnimation {
          notch = .min
        }
      }
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.92)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .fractional(0.18)
      }
    }
    .notchChange($notch)
    .onTranslation { translation in
      withAnimation(.linear(duration: 0.15)) {
        translationProgress = translation.progress
      }
    }
  }
  
}

struct EmailListView_Previews: PreviewProvider {
  static var previews: some View {
    EmailListView()
  }
}


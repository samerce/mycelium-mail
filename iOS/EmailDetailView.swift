import SwiftUI
import DynamicOverlay

enum EmailDetailViewEvent {
  case onOpenDetails, onCloseDetails
}

private enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

struct EmailDetailView: View {
  @ObservedObject private var model = MailController.shared.model
  @State private var seenTimer: Timer?
  @State private var notch: Notch = .min
  @State var translationProgress = 0.0
  
  private let mailCtrl = MailController.shared
  private var email: Email? { model.selectedEmail }
  
  var body: some View {
    ZStack(alignment: .top) {
      if email != nil {
        DetailView
        EmailListRow(email: email!, mode: .details)
          .ignoresSafeArea()
      }
    }
    .dynamicOverlay(ToolsDrawer)
    .dynamicOverlayBehavior(toolsDrawerBehavior)
    .ignoresSafeArea()
    .frame(width: rootWidth, height: rootHeight, alignment: .top)
    .clipped()
    .background(Color(.systemBackground))
  }
  
  private var DetailView: some View {
    WebView(content: email!.html ?? "")
      .background(Color(.systemBackground))
      .ignoresSafeArea()
      .onAppear {
        seenTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
          seenTimer = nil
          if email == nil { return }
          mailCtrl.markSeen([email!]) { error in
            // tell person about error
          }
        }
      }
      .onDisappear {
        seenTimer?.invalidate()
        seenTimer = nil
      }
  }
  
  private var ToolsDrawer: some View {
    EmailToolsDrawerView(email: email)
  }

  private var rootWidth: CGFloat {
    UIScreen.main.bounds.width
  }
  
  private var rootHeight: CGFloat {
    email == nil ? 0 : UIScreen.main.bounds.height
  }
  
  private var toolsDrawerBehavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.92)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .fractional(0.19)
      }
    }
    .notchChange($notch)
    .onTranslation { translation in
      withAnimation(.linear(duration: 0.15)) {
        translationProgress = translation.progress
      }
    }
  }
  
//  private func onOpenDetails() {
//    eventHandler(.onOpenDetails)
//    withAnimation {
//      collapsed = false
//    }
//  }
//
//  private func onCloseDetails() {
//    eventHandler(.onCloseDetails)
//    withAnimation {
//      collapsed = true
//    }
//  }
  
}


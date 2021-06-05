import SwiftUI
import DynamicOverlay
import Combine

private enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

struct EmailDetailView: View {
  @StateObject private var mailCtrl = MailController.shared
  @State private var seenTimer: Timer?
  @State private var notch: Notch = .min
  @State private var translationProgress = 0.0
  @State private var backGestureDistanceFromEdge: CGFloat?
  @State private var keyboardVisible = false
  
  private var email: Email? { mailCtrl.selectedEmail }
  
  var body: some View {
    ZStack(alignment: .top) {
      if email != nil {
        DetailView
          .dynamicOverlay(ToolsDrawer)
          .dynamicOverlayBehavior(toolsDrawerBehavior)
          .ignoresSafeArea()
          .clipped()
        
        EmailSenderDrawerView(email: email)
          .clipped()
      }
    }
    .frame(width: bodyWidth, height: bodyHeight, alignment: .top)
    .background(Color(.systemBackground))
    .clipped()
    .gesture(backGesture)
    .onReceive(Publishers.keyboardHeight) { keyboardHeight in
      keyboardVisible = keyboardHeight > 0
    }
  }
  
  private var DetailView: some View {
    WebView(content: email!.html ?? "")
      .background(Color(.systemBackground))
      .ignoresSafeArea()
      .onAppear {
        seenTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
          seenTimer = nil
          if let email = email {
            mailCtrl.markSeen([email]) { error in
              // tell person about error
            }
          }
        }
      }
      .onDisappear {
        seenTimer?.invalidate()
        seenTimer = nil
      }
  }
  
  private var ToolsDrawer: some View {
    EmailToolsDrawerView(email!)
      .clipped()
  }
  
  private var toolsDrawerBehavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.92)
      case .mid:
        return .fractional(0.54)
      case .min:
        return keyboardVisible ? .fractional(0.04) : .fractional(0.15)
      }
    }
    .notchChange($notch)
    .onTranslation { translation in
      withAnimation(.linear(duration: 0.15)) {
        translationProgress = translation.progress
      }
    }
  }
  
  private var backGesture: some Gesture {
    DragGesture()
      .onChanged { gesture in
        if gesture.startLocation.x < 36 {
          self.backGestureDistanceFromEdge =
            abs(gesture.location.x - gesture.startLocation.x)
        }
      }
      .onEnded { gesture in
        if let distance = self.backGestureDistanceFromEdge, distance > 54 {
          withAnimation { self.backGestureDistanceFromEdge = screenWidth }
          mailCtrl.deselectEmail()
        }
        self.backGestureDistanceFromEdge = nil
      }
  }
  
  private var bodyWidth: CGFloat {
    if let fromEdge = backGestureDistanceFromEdge {
      let percentOfScreen = fromEdge / screenWidth
      return screenWidth - (screenWidth * percentOfScreen)
    }
    return screenWidth
  }
  
  private var bodyHeight: CGFloat {
    return email == nil ? 0 : screenHeight
  }
  
}


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
  @State var backGestureDistanceFromEdge: CGFloat?
  
  private let mailCtrl = MailController.shared
  private var email: Email? { model.selectedEmail }
  
  var backGesture: some Gesture {
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
    .frame(width: rootWidth, height: rootHeight, alignment: .top)
    .background(Color(.systemBackground))
    .clipped()
    .gesture(backGesture)
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
      .clipped()
  }
  
  private var rootWidth: CGFloat {
    if let fromEdge = backGestureDistanceFromEdge {
      let percentOfScreen = fromEdge / UIScreen.main.bounds.width
      return screenWidth - (screenWidth * percentOfScreen)
    }
    return screenWidth
  }
  
  private var rootHeight: CGFloat {
//    if let distanceFromEdge = backGestureDistanceFromEdge {
//      let percentOfScreen = distanceFromEdge / UIScreen.main.bounds.width
//      return screenHeight - (screenHeight * percentOfScreen)
//    }
    return email == nil ? 0 : screenHeight
  }
  
  private var toolsDrawerBehavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.92)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .fractional(0.16)
      }
    }
    .notchChange($notch)
    .onTranslation { translation in
      withAnimation(.linear(duration: 0.15)) {
        translationProgress = translation.progress
      }
    }
  }
  
  private var screenWidth: CGFloat {
    UIScreen.main.bounds.width
  }
  private var screenHeight: CGFloat {
    UIScreen.main.bounds.height
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


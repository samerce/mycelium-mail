import SwiftUI
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
  @State private var sheetPresented = true
  
  var emailId: Email.ID?
  var email: Email? { mailCtrl.model.email(id: emailId) }
  
  var body: some View {
    Group {
      if (email == nil) { EmptyView() }
      else { DetailView }
    }
  }
  
  private var DetailView: some View {
    MessageContent
      .onAppear() {
        if let email = email {
          mailCtrl.selectEmail(email)
        }
      }
      .onReceive(Publishers.keyboardHeight) { keyboardHeight in
        keyboardVisible = keyboardHeight > 0
      }
      .navigationTitle(email?.subject ?? "")
      .navigationBarTitleDisplayMode(.inline)
  }
  
  private var MessageContent: some View {
    WebView(content: email?.html ?? "")
      .ignoresSafeArea()
      .background(Color(.systemBackground))
    //      .gesture(backGesture)
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
  
  private var Toolbar: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Title
    }
  }
  
  private var Title: some View {
    VStack {
      Text(mailCtrl.selectedEmail?.fromLine ?? "")
        .font(.system(size: 15, weight: .regular))
        .padding(.bottom, 6)
        .lineLimit(1)
      
      Text(mailCtrl.selectedEmail?.subject ?? "")
        .font(.system(size: 18, weight: .medium))
        .padding(.bottom, 12)
        .lineLimit(.max)
    }
//    .ignoresSafeArea()
    .frame(minWidth: screenWidth)
//    .background(OverlayBackgroundView())
  }
  
  // MARK: -
  
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


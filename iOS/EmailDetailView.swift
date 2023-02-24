import SwiftUI
import Combine
import CoreData


struct EmailDetailView: View {
  var email: Email
  
  @State private var seenTimer: Timer?
  @State private var keyboardHeight: CGFloat = 0
  
  private let mailCtrl = MailController.shared
  
  // MARK: - VIEW
  
  var body: some View {
    ZStack {
      if email.html.isEmpty { ProgressView().controlSize(.large) }
      else { Message }
    }
    .navigationTitle(email.subject)
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .bottom) {
      Spacer()
        .frame(height: keyboardHeight.isZero ? appSheetDetents.min : keyboardHeight)
    }
    .onReceive(Publishers.keyboardHeight) { keyboardHeight in
      self.keyboardHeight = keyboardHeight
    }
    .task {
      try? await mailCtrl.fetchHtml(for: email) // TODO: handle error
    }
  }
  
  private var Message: some View {
    WebView(content: email.html)
      .ignoresSafeArea()
      .background(Color(.systemBackground))
      .onAppear {
        seenTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
          seenTimer = nil
          mailCtrl.markSeen([email]) { error in
            // tell person about error
          }
        }
      }
      .onDisappear {
        seenTimer?.invalidate()
        seenTimer = nil
      }
  }
}


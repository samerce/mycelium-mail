import SwiftUI
import Combine
import CoreData


struct EmailDetailView: View {
  @StateObject private var mailCtrl = MailController.shared
  @State private var seenTimer: Timer?
  @State private var keyboardHeight: CGFloat = 0
  
  var email: Email
  
  // MARK: - VIEW
  
  var body: some View {
    WebView(content: email.html ?? "")
      .ignoresSafeArea()
      .navigationTitle(email.subject)
      .navigationBarTitleDisplayMode(.inline)
      .background(Color(.systemBackground))
      .task {
        // TODO: handle error
        try? await mailCtrl.fetchHtml(for: email)
      }
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
      .onReceive(Publishers.keyboardHeight) { keyboardHeight in
        self.keyboardHeight = keyboardHeight
      }
      .safeAreaInset(edge: .bottom) {
        Spacer()
          .frame(height: keyboardHeight.isZero ? appSheetDetents.min : keyboardHeight)
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
    .frame(minWidth: screenWidth)
  }
  
}


import SwiftUI
import Combine
import CoreData


struct EmailDetailView: View {
  var email: Email
  
  @State var seenTimer: Timer?
  @State var keyboardHeight: CGFloat = 0
  @State var titleBarHeight: CGFloat = 0
  
  private let mailCtrl = MailController.shared
  
  // MARK: - VIEW
  
  var body: some View {
    ZStack(alignment: .top) {
      if email.html.isEmpty { ProgressView().controlSize(.large) }
      else { Message }
      TitleBar
    }
    .toolbar(.hidden, for: .navigationBar)
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
    .ignoresSafeArea()
  }
  
  private let addressWidth = 42.0
  
  var TitleBar: some View {
    GeometryReader { geo in
      VStack(alignment: .leading, spacing: 0) {
        Spacer().frame(height: safeAreaInsets.top)
        
        HStack(alignment: .lastTextBaseline, spacing: 3) {
          Text(email.fromLine)
            .font(.system(size: 16, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .truncationMode(.tail)
            .lineLimit(1)
          
          Text(email.displayDate ?? "")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.81))
        }
        .padding(.bottom, 1)
        
        HStack(alignment: .lastTextBaseline, spacing: 0) {
          Text("To:")
            .font(.system(size: 13, weight: .medium))
            .padding(.trailing, 6)
          
          Text(email.toLine)
            .font(.system(size: 14))
            .lineLimit(1)
            .truncationMode(.tail)
        }
        .foregroundColor(.white.opacity(0.81))
        .padding(.bottom, 8)
        
        Text(email.subject)
          .font(.system(size: 20, weight: .medium))
          .padding(.bottom, 10)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .background(OverlayBackgroundView())
      .ignoresSafeArea()
      .onChange(of: geo.size.height) { titleBarHeight = $0 }
    }
  }
  
  var Message: some View {
    WebView(content: email.html, topInset: titleBarHeight)
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


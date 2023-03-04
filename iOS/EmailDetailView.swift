import SwiftUI
import Combine


struct EmailDetailView: View {
  var email: Email
  var isPreview = false
  
  @State var html = ""
  @State var seenTimer: Timer?
  @State var keyboardHeight: CGFloat = 0
  @State var titleBarHeight: CGFloat = 50
  @State var showingFromDetails = false
  
  var fromLine: String {
    (showingFromDetails || isPreview)
    ? email.from?.address ?? email.fromLine
    : email.fromLine
  }
  
  // MARK: - VIEW
  
  var body: some View {
    ZStack(alignment: html.isEmpty ? .center : .top) {
      if html.isEmpty { ProgressView().controlSize(.large) }
      else { Message }
      TitleBar
    }
    .toolbar(.hidden, for: .navigationBar)
    .safeAreaInset(edge: .bottom) {
      Spacer()
        .frame(height: keyboardHeight.isZero ? appSheetDetents.min : keyboardHeight)
    }
    .ignoresSafeArea()
    .task {
      try? await email.fetchHtml() // TODO: handle error
      html = email.html // TODO: why is this local state necessary?
    }
    .onReceive(Publishers.keyboardHeight) { keyboardHeight in
      self.keyboardHeight = keyboardHeight
    }
  }
  
  var TitleBar: some View {
    GeometryReader { geo in
      VStack(alignment: .leading, spacing: 0) {
        Spacer()
          .frame(height: isPreview ? 10 : safeAreaInsets.top)
        
        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text(fromLine)
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
          
          Text(email.displayDate ?? "")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.81))
        }
        .padding(.bottom, 3)
        
        Text(email.subject)
          .font(.system(size: 18, weight: .semibold))
          .padding(.bottom, 6)
          .lineLimit(1)
      }
      .padding(.horizontal, 12)
      .background(OverlayBackgroundView())
//      .onAppear {
//        titleBarHeight = screenHeight - geo.size.height
//        print("title bar height \(titleBarHeight)")
//      }
      .ignoresSafeArea()
      .onTapGesture {
        showingFromDetails.toggle()
      }
    }
  }
  
  var Message: some View {
    WebView(content: html, topInset: $titleBarHeight)
      .ignoresSafeArea()
      .background(Color(.systemBackground))
      .onAppear {
        markEmailSeen()
      }
      .onDisappear {
        seenTimer?.invalidate()
        seenTimer = nil
      }
  }
  
  func markEmailSeen() {
    seenTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
      seenTimer = nil
      
      Task {
        do {
          try await email.markSeen()
        }
        catch {
          // tell person about error
        }
      }
    }
  }
}


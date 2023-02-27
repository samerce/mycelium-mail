import SwiftUI
import Combine
import CoreData


private let mailCtrl = MailController.shared


struct EmailDetailView: View {
  var email: Email
  
  @EnvironmentObject var viewModel: ViewModel
  @State var seenTimer: Timer?
  @State var keyboardHeight: CGFloat = 0
  @State var titleBarHeight: CGFloat = 50
  @State var showingFromDetails = false
  
  var fromLine: String {
    showingFromDetails ? email.from?.address ?? "" : email.fromLine
  }
  
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
      try? await email.fetchHtml() // TODO: handle error
    }
    .ignoresSafeArea()
  }
  
  var TitleBar: some View {
    GeometryReader { geo in
      VStack(alignment: .leading, spacing: 0) {
        Spacer().frame(height: safeAreaInsets.top)
        
        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text(fromLine)
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
          
          Text(email.displayDate ?? "")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.81))
        }
        .padding(.bottom, 1)
        
//        HStack(alignment: .lastTextBaseline, spacing: 0) {
//          Text("To:")
//            .font(.system(size: 13, weight: .medium))
//            .padding(.trailing, 6)
//
//          Text(email.toLine)
//            .font(.system(size: 14))
//            .lineLimit(1)
//        }
//        .foregroundColor(.white.opacity(0.81))
//        .padding(.bottom, 6)
        
        Text(email.subject)
          .font(.system(size: 18, weight: .semibold))
          .padding(.bottom, 10)
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
    WebView(content: email.html, topInset: $titleBarHeight)
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


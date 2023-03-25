import SwiftUI
import Introspect


struct FirstStartView: View {
  @ObservedObject var mailCtrl = MailController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var accountCtrl = AccountController.shared
  @AppStorage(AppStorageKeys.completedInitialDownload) var completedInitialDownload = false
  
  // MARK: - VIEW
  
  var body: some View {
    ZStack {
      if accountCtrl.accounts.isEmpty {
        LogInPrompt
      }
      else if mailCtrl.threadsInSelectedBundle.isEmpty {
        ProgressView("DOWNLOADING EMAILS")
          .controlSize(.large)
          .font(.system(size: 18))
          .onReceive(mailCtrl.$threadsInSelectedBundle) { emails in
            if !emails.isEmpty {
              completedInitialDownload = true
              withAnimation { sheetCtrl.sheet = .inbox }
            }
          }
      }
    }
    .height(screenHeight - safeAreaInsets.top)
  }
  
  private var LogInPrompt: some View {
    VStack(alignment: .center) {
      Text("psymail")
        .font(.system(size: 36, weight: .black))
        .padding(.top, 12)
        .padding(.bottom, 18)
      
      Text("✨ email nirvana awaits ✨")
        .font(.system(size: 18, weight: .light))
        .foregroundColor(.white.opacity(0.69))
        .padding(.bottom, 27)
      
      Button {
        AccountController.shared.signIn()
        EmailBundleController.shared.initDefaultBundles()
      } label: {
        Text("SIGN IN")
          .font(.system(size: 18))
          .padding(9)
      }
      .buttonStyle(.borderedProminent)
      .tint(.psyAccent)
    }
    .padding(.horizontal, 18)
  }
  
}

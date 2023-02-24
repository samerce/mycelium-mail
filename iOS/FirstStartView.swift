import SwiftUI
import Introspect


struct FirstStartView: View {
  @EnvironmentObject var viewModel: ViewModel
  
  var body: some View {
    if AccountController.shared.model.accounts.isEmpty {
      LogInPrompt
    }
    else if viewModel.emailsInSelectedBundle.isEmpty {
      ProgressView("DOWNLOADING EMAILS")
        .controlSize(.large)
        .font(.system(size: 18))
        .onReceive(viewModel.$emailsInSelectedBundle) { emails in
          if !emails.isEmpty {
            withAnimation { viewModel.appSheetMode = .inboxTools }
          }
        }
    }
  }
  
  private var LogInPrompt: some View {
    VStack(alignment: .center) {
      Text("psymail")
        .font(.system(size: 36, weight: .black))
        .padding(.top, 12)
        .padding(.bottom, 18)
      
      Text("✨ EMAIL NIRVANA AWAITS ✨")
        .font(.system(size: 18, weight: .light))
        .foregroundColor(.white.opacity(0.69))
        .padding(.bottom, 27)
      
      Button {
        AccountController.shared.signIn()
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

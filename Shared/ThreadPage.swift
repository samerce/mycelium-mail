import SwiftUI


struct ThreadPage: View {
  var thread: EmailThread
  var email: Email { thread.lastReceivedEmail}
  
  var body: some View {
    VStack(spacing: 0) {
      Header
        .padding(.bottom, 6)
      
      MessageView(email: email)
        .allowsHitTesting(false)
        .frame(maxHeight: 540, alignment: .top) // TODO: how to figure out dynamic value here?
        .clipped()
        .cornerRadius(12)
    }
    .safeAreaInset(edge: .bottom) {
      Spacer().height(appSheetDetents.min)
    }
    .padding(9)
  }
  
  var Header: some View {
    VStack {
      Text(email.subject)
        .font(.system(size: 15, weight: .semibold))
        .lineLimit(1)
      
      Text(email.fromLine)
    }
    .frame(maxWidth: .infinity)
    .padding(12)
    .background(Color(.tertiarySystemFill))
    .cornerRadius(12)
    .foregroundColor(.white)
  }
  
}


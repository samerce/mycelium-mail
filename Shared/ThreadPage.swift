import SwiftUI


private let dataCtrl = PersistenceController.shared
private let mailCtrl = MailController.shared


struct ThreadPage: View {
  @State var thread: EmailThread
  var email: Email { thread.lastReceivedEmail}
  
  var body: some View {
    VStack(spacing: 0) {
      NavigationLink(value: thread) {
        VStack(spacing: 0) {
          Header
            .padding(.bottom, 6)
          
          MessageView(email: email)
            .allowsHitTesting(false)
            .frame(maxHeight: 505, alignment: .top) // TODO: how to figure out dynamic value here?
            .clipped()
            .cornerRadius(12)
            .padding(.bottom, 12)
        }
      }
      
      Toolbar
        .padding(.bottom, 12)
    }
    .padding(9)
    .frame(maxHeight: .infinity, alignment: .top)
  }
  
  var Header: some View {
    VStack {
      Text(email.subject)
        .font(.system(size: 14, weight: .semibold))
        .lineLimit(1)
      
      Text(email.fromLine)
        .font(.system(size: 14))
    }
    .frame(maxWidth: .infinity)
    .padding(9)
    .background(Color(.tertiarySystemFill))
    .cornerRadius(12)
    .foregroundColor(.white)
  }
  
  var Toolbar: some View {
    HStack(spacing: 18) {
      Button {
        mailCtrl.markThread(thread, seen: !thread.seen)
      } label: {
        ButtonImage(name: thread.seen ? "envelope.badge.fill" : "envelope.open.fill", size: 27)
      }
      
      Menu { MoveToBundleMenu(thread: thread) } label: {
        ButtonImage(name: "mail.stack.fill", size: 27)
      }
      
      Button {
        mailCtrl.markThread(thread, flagged: !thread.flagged)
      } label: {
        ButtonImage(name: thread.flagged ? "pin.slash.fill" : "pin.fill", size: 27)
      }
    }
  }
  
}

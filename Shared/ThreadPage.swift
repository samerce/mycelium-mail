import SwiftUI


private let dataCtrl = PersistenceController.shared


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
            .frame(maxHeight: 494, alignment: .top) // TODO: how to figure out dynamic value here?
            .clipped()
            .cornerRadius(12)
            .padding(.bottom, 12)
        }
      }
      
      Toolbar
    }
    .safeAreaInset(edge: .bottom) {
      Spacer().height(appSheetDetents.min)
    }
    .padding(9)
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
        Task {
          try await thread.markSeen(!thread.seen)
          dataCtrl.save()
        }
      } label: {
        ButtonImage(name: thread.seen ? "envelope.badge" : "envelope.open", size: 27)
      }
      
      Menu { MoveToBundleMenu(thread: thread) } label: {
        ButtonImage(name: "mail.stack", size: 27)
      }
      
      Button {
        Task {
          try await thread.markFlagged(!thread.flagged)
          dataCtrl.save()
        }
      } label: {
        ButtonImage(name: thread.flagged ? "star.fill" : "star", size: 27)
      }
    }
  }
  
}

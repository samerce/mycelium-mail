import SwiftUI
import DynamicOverlay
import Introspect

private var mailCtrl = MailController.shared

struct EmailToolsDrawerView: View {
  var email: Email
  
  @State private var replying = false
  @State private var replyText: String = ""
  @State private var replyTextField: UITextField?
  
  init(_ email: Email) { self.email = email }
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      DrawerCapsule()
        .padding(.vertical, 6)
      
      HStack(spacing: 0) {
        AddMediaButton
        ArchiveButton
        TagButton
        TrashButton
        FlagButton
        ReplyTextField
        ReplyButton
      }
      .frame(maxWidth: .infinity, minHeight: 40)
      .padding(0)
      .padding(.horizontal, replying ? 6 : 24)
      
      VStack(spacing: 0) {
        Divider()
          .padding(.top, 9)
        
        HStack(spacing: 0) {
          Spacer()
          BackToEmailListButton
          Spacer().frame(width: 9)
          LongDate
          Spacer().frame(width: 9)
          ComposeButton
        }
        .frame(maxWidth: .infinity)
        
        Spacer()
      }
      .padding(.horizontal, 24)
      .clipped()
    }
    .frame(width: screenWidth, height: screenHeight, alignment: .topLeading)
    .background(OverlayBackgroundView())
    .ignoresSafeArea()
  }
  
  private var AddMediaButton: some View {
    Button(action: {}) {
      ZStack {
        SystemImage("plus.circle", size: 24)
      }
      .frame(minWidth: 36)
    }
    .frame(maxWidth: replying ? 36 : 0)
    .opacity(replying ? 1 : 0)
    .clipped()
  }
  
  private var ArchiveButton: some View {
    Button(action: {}) {
      ZStack {
        SystemImage("archivebox", size: 24)
      }
      .frame(width: 36, height: 40)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var TagButton: some View {
    Button(action: {}) {
      SystemImage("tag", size: 24)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var TrashButton: some View {
    Button(action: { mailCtrl.deleteEmails([email]) }) {
      SystemImage("trash", size: 24)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var FlagButton: some View {
    Button(action: { mailCtrl.flagEmails([email]) }) {
      SystemImage("flag", size: 24)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var ReplyTextField: some View {
    TextField("", text: $replyText)
      .introspectTextField {
        replyTextField = $0
      }
      .frame(maxWidth: replying ? .infinity : 0)
      .opacity(replying ? 1 : 0)
      .clipped()
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .cornerRadius(108)
  }
  
  private var ReplyButton: some View {
    Button(action: { withAnimation {
      if replying {
        // send reply
        replyText = ""
      } else {
        replyTextField?.becomeFirstResponder()
      }
      
      replying.toggle()
    }}) {
      ZStack {
        SystemImage(
          replying ? "arrow.up.circle.fill" : "arrowshape.turn.up.left",
          size: 24
        )
      }
      .frame(minWidth: replying ? 36 : nil)
    }
    .frame(maxWidth: replying ? 36 : .infinity)
  }
  
  private var BackToEmailListButton: some View {
    Button(action: { mailCtrl.deselectEmail() }) {
      ZStack {
        SystemImage("mail.stack", size: 27)
      }
      .frame(width: 54, height: 50, alignment: .leading)
    }
  }
  
  private var LongDate: some View {
    Text(email.longDisplayDate ?? "")
      .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
      .font(.system(size: 16, weight: .light))
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .lineLimit(1)
  }
  
  private var ComposeButton: some View {
    Button(action: {}) {
      ZStack {
        SystemImage("square.and.pencil", size: 27)
      }
      .frame(width: 54, height: 50, alignment: .trailing)
    }
  }
  
  private func SystemImage(_ name: String, size: CGFloat) -> some View {
    Image(systemName: name)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .foregroundColor(.psyAccent)
      .font(.system(size: size, weight: .light, design: .default))
      .frame(width: size, height: size)
      .contentShape(Rectangle())
      .clipped()
  }
  
}

struct EmailToolsDrawerView_Previews: PreviewProvider {
  static var previews: some View {
    EmailToolsDrawerView(Email())
  }
}

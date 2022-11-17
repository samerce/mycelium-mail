import SwiftUI
import Introspect

private let Tools = [
  "forward": "arrowshape.turn.up.right",
  "mark unread": "envelope",
  "junk": "xmark.bin",
  "mute": "bell.slash",
  "notify": "bell",
  "block": "nosign",
  "archive": "archivebox",
  "save as pdf": "square.and.arrow.down",
  "print": "printer"
]

private let ToolImageSize: CGFloat = 36
private var toolGridItems: [GridItem] {
  Array(repeating: .init(.flexible(minimum: 54, maximum: .infinity)), count: 3)
}

private enum NoteTarget: String, CaseIterable, Equatable {
  case email, contact
}

private var mailCtrl = MailController.shared

struct EmailToolsDrawerView: View {
  var email: Email
  
  @State private var replying = false
  @State private var replyText: String = ""
  @State private var replyTextField: UITextField?
  
  @State private var noting = false
  @State private var noteText: String = "add note"
  @State private var noteTextField: UITextField?
  @State private var noteTarget: NoteTarget = .email
  
  init(_ email: Email) { self.email = email }
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      DrawerCapsule()
        .padding(.vertical, 6)
      
      HStack(spacing: 0) {
        AddMediaButton
        UnsubscribeButton
        TagButton
        TrashButton
        StarButton
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
        
        Spacer().frame(height: 27)
        MoreTools
        
        Spacer().frame(height: 27)
        Notes
      }
      .padding(.horizontal, 18)
      .clipped()
    }
    .frame(width: screenWidth, height: screenHeight, alignment: .topLeading)
    .background(OverlayBackgroundView())
    .foregroundColor(.psyAccent)
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
  
  private var UnsubscribeButton: some View {
    Button(action: {}) {
      ZStack {
        SystemImage("hand.raised", size: 24)
      }
      .frame(width: 36, height: 40)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
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
      ZStack {
        SystemImage("trash", size: 24)
      }
      .frame(maxWidth: .infinity, maxHeight: 36)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var StarButton: some View {
    Button(action: { mailCtrl.flagEmails([email]) }) {
      SystemImage("star", size: 24)
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
  
  private var MoreTools: some View {
    LazyVGrid(columns: toolGridItems, spacing: 9) {
      ForEach(Array(Tools.keys), id: \.self) { filter in
        Button(action: {}) {
          VStack(spacing: 9) {
            Image(systemName: Tools[filter] ?? "")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: ToolImageSize, height: ToolImageSize)
              .font(.system(size: ToolImageSize, weight: .light))
              .contentShape(Rectangle())
            
            Text(filter)
              .font(.system(size: 13))
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity, maxHeight: 108)
          .padding(18)
          .background(Color(.tertiarySystemBackground))
          .foregroundColor(Color(.secondaryLabel))
          .cornerRadius(9)
          .shadow(radius: 3)
        }
      }
    }
  }
  
  private var Notes: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("NOTES")
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: 12, weight: .light))
          .foregroundColor(Color(.gray))
        
        Spacer()
        
        Picker("", selection: $noteTarget) {
          ForEach(NoteTarget.allCases, id: \.rawValue) { target in
            Text(target.rawValue)
              .font(.system(size: 12))
              .tag(target)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(maxWidth: 168)
      }
      
      Spacer().frame(height: 12)
      
      if noting { Editor }
      else {
        Button(action: {
          withAnimation { noting = true }
        }) {
          HStack(spacing: 0) {
            Text("add \(noteTarget.rawValue) note")
              .font(.system(size: 18))
              .padding(.horizontal, 18)
              .padding(.vertical, 18)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            SystemImage("note.text.badge.plus", size: 24)
              .padding(.trailing, 18)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.tertiarySystemBackground))
          .cornerRadius(9)
        }
      }
    }
    .foregroundColor(Color(.secondaryLabel))
  }
  
  private var Editor: some View {
    ZStack { // so it grows as text grows
      TextEditor(text: $noteText)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .lineSpacing(1.4)
        .minimumScaleFactor(0.9)
        .cornerRadius(9)
        .shadow(radius: 3)
    }
    .frame(maxHeight: 216)
    .font(.system(size: 16, weight: .light))
    .foregroundColor(noting ? .white : .psyAccent.opacity(0.9))
  }
  
  private func SystemImage(_ name: String, size: CGFloat) -> some View {
    Image(systemName: name)
      .resizable()
      .aspectRatio(contentMode: .fit)
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

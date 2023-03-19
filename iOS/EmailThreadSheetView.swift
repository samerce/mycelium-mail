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
  "print": "printer",
  "unsubscribe": "hand.raised"
]

private let ToolImageSize: CGFloat = 36
private var toolGridItems: [GridItem] {
  Array(repeating: .init(.flexible(minimum: 54, maximum: .infinity)), count: 2)
}

private enum NoteTarget: String, CaseIterable, Equatable {
  case email, contact
}


struct EmailThreadSheetView: View {
  @ObservedObject var mailCtrl = MailController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var navCtrl = NavController.shared
  
  @State private var replying = false
  @State private var replyText: String = ""
  @State private var replyTextField: UITextField?
  
  @State private var noting = false
  @State private var noteText: String = "add note"
  @State private var noteTextField: UITextField?
  @State private var noteTarget: NoteTarget = .email
  
  var thread: EmailThread? { mailCtrl.selectedThreads.first }
  
  // MARK: - VIEW
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SheetHandle()
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
      
      HStack(spacing: 0) {
        AddMediaButton
        TagButton
        StarButton
        TrashButton
        BundleButton
        ReplyTextField
        ReplyButton
      }
      .frame(maxWidth: .infinity, minHeight: 40)
      .padding(0)
      
      VStack(spacing: 0) {
        Divider()
          .padding(.top, 9)
        
        HStack(spacing: 0) {
          BackToEmailListButton
          AccountLabel
            .padding(.horizontal, 9)
          ComposeButton
        }
        .frame(maxWidth: .infinity)
        
        Spacer().frame(height: 12)
        MoreTools
        
        Spacer().frame(height: 27)
        Notes
      }
      .padding(.horizontal, 18)
      .clipped()
    }
  }
  
  let cButtonSize = 22.0
  
  private var AddMediaButton: some View {
    Button(action: {}) {
      ButtonImage(name: "plus.circle", size: cButtonSize)
    }
    .frame(maxWidth: replying ? 36 : 0)
    .opacity(replying ? 1 : 0)
    .clipped()
  }
  
  @ViewBuilder
  private var BundleButton: some View {
    Menu {
      if let thread = thread {
        MoveToBundleMenu(thread: thread, onMove: {
          navCtrl.goBack(withSheet: .inbox)
        })
      } else { EmptyView() }
    } label: {
      ButtonImage(name: "mail.stack", size: cButtonSize)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var ArchiveButton: some View {
    Button(action: {}) {
      ButtonImage(name: "archivebox", size: cButtonSize)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var TagButton: some View {
    Button(action: {}) {
      ButtonImage(name: "tag", size: cButtonSize)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var TrashButton: some View {
    Button {
      Task {
        navCtrl.goBack(withSheet: .inbox)
        try? await thread?.moveToTrash() // TODO: handle error
        PersistenceController.shared.save()
      }
    } label: {
      ButtonImage(name: "trash", size: cButtonSize)
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var StarButton: some View {
    Button {
      Task {
        try? await thread?.markFlagged() // TODO: handle error
      }
    } label: {
      ButtonImage(name: "star", size: cButtonSize)
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
      ButtonImage(
        name: replying ? "arrow.up.circle.fill" : "arrowshape.turn.up.left",
        size: cButtonSize
      )
      .frame(minWidth: replying ? 36 : nil)
    }
    .frame(maxWidth: replying ? 36 : .infinity)
  }
  
  private var BackToEmailListButton: some View {
    Button {
      navCtrl.goBack(withSheet: .inbox)
    } label: {
      ButtonImage(name: "chevron.backward", size: cButtonSize, weight: .regular)
    }
  }
  
  private var AccountLabel: some View {
    Label(thread?.account.address ?? "", systemImage: "tray.full")
      .frame(maxWidth: .infinity, minHeight: 50)
      .font(.system(size: 14, weight: .light))
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .lineLimit(1)
  }
  
  private var ComposeButton: some View {
    Button(action: {}) {
      ButtonImage(name: "square.and.pencil", size: cButtonSize, weight: .regular)
    }
  }
  
  private var MoreTools: some View {
    LazyVGrid(columns: toolGridItems, spacing: 9) {
      ForEach(Array(Tools.keys), id: \.self) { filter in
        Button(action: {}) {
          Label {
            ButtonImage(name: Tools[filter]!, color: .white)
          } icon: {
            Text(filter)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .font(.system(size: 15))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 9)
          .padding(.horizontal, 12)
          .background(OverlayBackgroundView(blurStyle: .systemThickMaterial))
          .foregroundColor(.primary)
          .cornerRadius(12)
        }
      }
    }
  }
  
  private var Notes: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("NOTES")
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: 12))
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
              .font(.system(size: 15))
              .padding(.trailing, 12)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            SystemImage(name: "note.text.badge.plus", size: 22, color: .white)
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(OverlayBackgroundView(blurStyle: .systemThickMaterial))
          .cornerRadius(12)
        }
      }
    }
    .foregroundColor(.white)
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
    .font(.system(size: 15, weight: .thin))
    .foregroundColor(noting ? .white : .psyAccent.opacity(0.9))
  }
  
}

struct EmailThreadSheetView_Previews: PreviewProvider {
  static var previews: some View {
    EmailThreadSheetView()
  }
}

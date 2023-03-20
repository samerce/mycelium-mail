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
  @ObservedObject var dataCtrl = PersistenceController.shared
  @ObservedObject var mailCtrl = MailController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var navCtrl = NavController.shared
  
  @State private var replying = false
  @State private var replyText: String = ""
  @FocusState var replyFieldFocused: Bool
  
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
        CancelReplyButton
        ArchiveButton
        StarButton
        TrashButton
        BundleButton
        ReplyTextField
        ReplyButton
      }
      .frame(maxWidth: .infinity, minHeight: 40)
      
      VStack(spacing: 0) {
        Divider()
          .padding(.top, 9)
        
        HStack(spacing: 0) {
          BackToEmailListButton
          AccountLabel
          ComposeButton
        }
        .frame(maxWidth: .infinity)
        
        Spacer().frame(height: 18)
        MoreTools
        
        Spacer().frame(height: 27)
        Notes
      }
      .padding(.horizontal, 6)
      .clipped()
    }
    .padding(.horizontal, 12)
  }
  
  let cButtonSize = 22.0
  
  private var CancelReplyButton: some View {
    Button {
      replying = false
    } label: {
      ButtonImage(name: "xmark.circle", size: cButtonSize)
    }
    .frame(maxWidth: replying ? 36 : 0)
    .opacity(replying ? 1 : 0)
    .clipped()
  }
  
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
          save()
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
    Button {
      Task {
        try await thread?.archive()
        save()
        navCtrl.goBack(withSheet: .inbox)
      }
    } label: {
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
        try? await thread?.moveToTrash() // TODO: handle error
        save()
        navCtrl.goBack(withSheet: .inbox)
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
        try? await thread!.markFlagged(!thread!.flagged) // TODO: handle error
        save()
      }
    } label: {
      ButtonImage(
        name: (thread == nil || !thread!.flagged) ? "star" : "star.fill",
        size: cButtonSize
      )
    }
    .frame(maxWidth: replying ? 0 : .infinity)
    .opacity(replying ? 0 : 1)
    .clipped()
  }
  
  private var ReplyTextField: some View {
    TextField("", text: $replyText)
      .frame(maxWidth: replying ? .infinity : 0)
      .opacity(replying ? 1 : 0)
      .clipped()
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .cornerRadius(108)
      .focused($replyFieldFocused)
      .onChange(of: replying) { _ in
        if replying {
          replyFieldFocused = true
        } else {
          replyFieldFocused = false
          sheetCtrl.setDetent(AppSheet.emailThread.initialDetent)
        }
      }
  }
  
  private var ReplyButton: some View {
    Button(action: { withAnimation {
      if replying {
        Task {
          try? await thread?.lastReceivedEmail.sendReply(replyText) // TODO: handle error
          replyText = ""
        }
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
  
  @State var showingHeaderDetails = false
  var fromLine: String {
    guard let thread = thread
    else { return "unknown sender" }
    
    return showingHeaderDetails
    ? thread.from.map { $0.address }.joined(separator: ", ")
    : thread.fromLine
  }
  var accountLine: String {
    // TODO: use account nickname instead of hardcoded string
    (showingHeaderDetails ? thread?.account.address : "samerce") ?? ""
  }
  
  private var AccountLabel: some View {
    VStack(alignment: .center, spacing: 0) {
      Text(fromLine)
        .font(.system(size: 12))
        .padding(.bottom, 2)
      
      Label {
        Text(accountLine)
          .font(.system(size: 12, weight: .light))
      } icon: {
        SystemImage(name: "tray.full", size: 12, color: .secondary, weight: .light)
      }
    }
    .foregroundColor(.secondary)
    .lineLimit(1)
    .frame(maxWidth: .infinity, minHeight: 50)
    .padding(.horizontal, 12)
    .contentShape(Rectangle())
    .onTapGesture {
      showingHeaderDetails.toggle()
    }
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
          .background(OverlayBackgroundView(blurStyle: .prominent))
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
        
//        Picker("", selection: $noteTarget) {
//          ForEach(NoteTarget.allCases, id: \.rawValue) { target in
//            Text(target.rawValue)
//              .font(.system(size: 12))
//              .tag(target)
//          }
//        }
//        .pickerStyle(SegmentedPickerStyle())
//        .frame(maxWidth: 168)
      }
      
      Spacer().frame(height: 12)
      
      if noting { Editor }
      else {
        Button(action: {
          withAnimation { noting = true }
        }) {
          HStack(spacing: 0) {
            Text("add note")
              .font(.system(size: 15))
              .padding(.trailing, 12)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            SystemImage(name: "note.text.badge.plus", size: 22, color: .white)
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(OverlayBackgroundView(blurStyle: .prominent))
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
        .cornerRadius(12)
    }
    .frame(maxHeight: 216)
    .font(.system(size: 15, weight: .thin))
    .foregroundColor(noting ? .white : .psyAccent.opacity(0.9))
  }
  
  func save() {
    dataCtrl.save()
    dataCtrl.context.refresh(thread!, mergeChanges: true)
  }
  
}

struct EmailThreadSheetView_Previews: PreviewProvider {
  static var previews: some View {
    EmailThreadSheetView()
  }
}

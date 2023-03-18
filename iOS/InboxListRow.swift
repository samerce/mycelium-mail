import SwiftUI


struct InboxListRow: View {
  var thread: EmailThread
  
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var alertCtrl = AppAlertController.shared
  
  var selectedBundle: EmailBundle { bundleCtrl.selectedBundle }
  var bundles: [EmailBundle] { bundleCtrl.bundles }
  
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      if !thread.seen {
        Rectangle()
          .fill(Color.psyAccent)
          .frame(maxWidth: 4, maxHeight: 14)
          .cornerRadius(4)
          .offset(x: 4, y: 2)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .lastTextBaseline) {
          Text(thread.fromLine)
            .font(.system(size: 15, weight: thread.seen ? .medium : .bold))
            .lineLimit(1)

          Spacer()

          Text(thread.displayDate)
            .font(.system(size: 12, weight: thread.seen ? .light : .regular))
            .foregroundColor(Color.secondary)

          Image(systemName: "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(thread.seen ? .secondary : .psyAccent)
            .frame(width: 12, height: 12)
            .offset(y: 1)
        }
        .clipped()
        
        Text(thread.subject)
          .font(.system(size: 13, weight: thread.seen ? .light : .medium))
          .lineLimit(1)
      }
      .foregroundColor(Color.primary)
      .padding(.trailing, 9)
      .padding(.leading, 12)
    }
    .frame(height: 54)
    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    .contentShape(Rectangle())
    .swipeActions(edge: .trailing) { swipeActions }
    .contextMenu { contextMenu } preview: {
      EmailThreadView(thread: thread, isPreview: true)
        .frame(width: screenWidth, height: screenHeight / 2)
    }
  }
  
  @ViewBuilder
  var swipeActions: some View {
    Button(role: .destructive) {
      Task {
        try? await thread.moveToTrash() // TODO: handle error
        PersistenceController.shared.save()
      }
    } label: {
      Label("trash", systemImage: "trash")
    }
    .tint(.pink)
    
    Button { print("bundle") } label: {
      Label("bundle", systemImage: "giftcard")
    }
    Button { print("bundle") } label: {
      Label("follow up", systemImage: "pin")
    }
    Button { print("note") } label: {
      Label("note", systemImage: "note.text")
    }
    Button { print("notification") } label: {
      Label("notifications", systemImage: "bell")
    }
  }
  
  @ViewBuilder
  var contextMenu: some View {
    Text("MOVE TO BUNDLE")
    
    ForEach(bundles, id: \.objectID) { bundle in
      contextMenuButtonForBundle(bundle)
    }
    
    Divider()
    
    Button {
      withAnimation {
        bundleCtrl.threadToMoveToNewBundle = thread
        sheetCtrl.sheet = .createBundle
      }
    } label: {
      Text("new bundle")
      SystemImage(name: "plus", size: 12)
    }
  }
  
  func contextMenuButtonForBundle(_ bundle: EmailBundle) -> some View {
    Button {
      alertCtrl.show(message: "moved to \(bundle.name)", icon: bundle.icon, delay: 0.54, action: {
        alertCtrl.hide()
        sheetCtrl.sheet = .bundleSettings
      }, actionLabel: "EDIT")
      
      withAnimation {
        let _ = Task {
          do {
            try await MailController.shared.moveThread(thread, fromBundle: selectedBundle, toBundle: bundle)
          }
          catch {
            alertCtrl.show(message: "failed to move message", icon: "xmark", delay: 1)
          }
        }
      }
    } label: {
      Text(bundle.name)
      SystemImage(name: bundle.icon, size: 12)
    }
  }
  
}

import SwiftUI


private let dataCtrl = PersistenceController.shared
private let mailCtrl = MailController.shared


struct InboxListRow: View {
  var thread: EmailThread
  
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
    .swipeActions(edge: .leading) { swipeActionsLeading }
    .swipeActions(edge: .trailing) { swipeActionsTrailing }
    .contextMenu { MoveToBundleMenu(thread: thread) } preview: {
      EmailThreadView(thread: thread, isPreview: true)
        .frame(width: screenWidth, height: screenHeight / 2)
    }
  }
  
  @ViewBuilder
  var swipeActionsLeading: some View {
    Button {
      mailCtrl.markThread(thread, seen: !thread.seen)
    } label: {
      Label("mark \(thread.seen ? "unread" : "read")",
            systemImage: thread.seen ? "envelope.badge.fill" : "envelope.open")
    }
  }
  
  @ViewBuilder
  var swipeActionsTrailing: some View {
    Button(role: .destructive) {
      mailCtrl.trashThread(thread)
    } label: {
      Label("trash", systemImage: "trash")
    }
    .tint(.pink)
    
    Button {
    
    } label: {
      Label("bundle", systemImage: "mail.stack")
    }
    
    Button {
      mailCtrl.markThread(thread, flagged: !thread.flagged)
    } label: {
      Label("pin", systemImage: thread.flagged ? "pin.slash.fill" : "pin")
    }
    
    Button {
      Timer.after(1) { _ in // leave time for row closing animation
        mailCtrl.moveThread(thread, toBundleNamed: "archive", always: false)
      }
    } label: {
      Label("archive", systemImage: "archivebox")
    }
    
    Button { print("notification") } label: {
      Label("notifications", systemImage: "bell")
    }
  }
  
}

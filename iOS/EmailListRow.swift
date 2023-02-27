import SwiftUI


struct EmailListRow: View {
  var email: Email
  
  @EnvironmentObject var viewModel: ViewModel
  @EnvironmentObject var alert: AppAlertViewModel
  
  var selectedBundle: EmailBundle { viewModel.selectedBundle }
  var bundles: [EmailBundle] { viewModel.bundles }
  
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      if !email.seen {
        Rectangle()
          .fill(Color.psyAccent)
          .frame(maxWidth: 4, maxHeight: 14)
          .cornerRadius(4)
          .offset(x: 4, y: 2)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .lastTextBaseline) {
          Text(email.fromLine)
            .font(.system(size: 15, weight: email.seen ? .medium : .bold))
            .lineLimit(1)

          Spacer()

          Text(email.displayDate ?? "")
            .font(.system(size: 12, weight: email.seen ? .light : .regular))
            .foregroundColor(Color.secondary)

          Image(systemName: "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(email.seen ? .secondary : .psyAccent)
            .frame(width: 12, height: 12)
            .offset(y: 1)
        }
        .clipped()
        
        Text(email.subject)
          .font(.system(size: 13, weight: email.seen ? .light : .medium))
          .lineLimit(1)
      }
      .foregroundColor(Color.primary)
      .padding(.trailing, 9)
      .padding(.leading, 12)
    }
    .frame(height: 54)
    .listRowInsets(.init(top: 3, leading: 0, bottom: 3, trailing: 0))
    .contentShape(Rectangle())
    .swipeActions(edge: .trailing) { swipeActions }
    .contextMenu { contextMenu } preview: {
      EmailDetailView(email: email, isPreview: true)
        .frame(width: screenWidth, height: screenHeight / 2)
    }
  }
  
  @ViewBuilder
  var swipeActions: some View {
    Button(role: .destructive) {
      MailController.shared.deleteEmails([email])
    } label: {
      Label("trash", systemImage: "trash")
    }
    .tint(.red)
    
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
        viewModel.emailToMoveToNewBundle = email
        viewModel.appSheet = .createBundle
      }
    } label: {
      Text("new bundle")
      SystemImage(name: "plus", size: 12)
    }
  }
  
  func contextMenuButtonForBundle(_ bundle: EmailBundle) -> some View {
    Button {
      withAnimation {
        let _ = Task {
          do {
            try await MailController.shared.moveEmail(email, fromBundle: selectedBundle, toBundle: bundle)
            alert.show(message: "MOVED TO\n\(bundle.name)", icon: bundle.icon, delay: 1)
          }
          catch {
            alert.show(message: "failed to move message", icon: "xmark", delay: 1)
          }
        }
      }
    } label: {
      Text(bundle.name)
      SystemImage(name: bundle.icon, size: 12)
    }
  }
  
}

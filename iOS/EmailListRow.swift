import SwiftUI

enum EmailListRowMode {
  case summary, details
}

struct EmailListRow: View {
  @EnvironmentObject private var appAlert: AppAlert
  @EnvironmentObject private var viewModel: ViewModel
  
  private var selectedBundle: EmailBundle? {
    viewModel.selectedBundle
  }
  private var bundles: [EmailBundle] {
    viewModel.bundles
  }
  
  var email: Email
  var mode: EmailListRowMode = .summary
  
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      if !email.seen && mode == .summary {
        Rectangle()
          .fill(Color.psyAccent)
          .frame(maxWidth: 4, maxHeight: 14)
          .cornerRadius(4)
          .offset(x: 4, y: 2)
      }
      VStack(alignment: .leading, spacing: mode == .summary ? 4 : 6) {
//        if mode == .details { Spacer().frame(height: 30) }
        
        HStack(alignment: .lastTextBaseline) {
          Text(email.fromLine)
            .font(.system(size: 15, weight: email.seen ? .medium : .bold))
            .lineLimit(1)
            .if(mode == .summary) { view in
              view
                .font(.system(size: 15, weight: .heavy))
            }
            .if(mode == .details) { $0.font(.system(size: 20, weight: .bold)) }
          Spacer()
          Text(email.displayDate ?? "")
            .font(.system(size: 12, weight: email.seen ? .light : .regular))
            .foregroundColor(Color.secondary)
            .if(mode == .details) { $0.hidden().frame(width: 0) }
          Image(systemName: mode == .details ? "chevron.down" : "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(email.seen ? .secondary : .psyAccent)
            .if(mode == .details) { $0.frame(width: 18, height: 18) }
            .if(mode == .summary) { $0.frame(width: 12, height: 12) }
            .offset(x: 0, y: 1)
        }
        .clipped()
        
        Text(email.subject)
          .if(mode == .summary) { view in
            view
              .font(.system(size: 13, weight: email.seen ? .light : .regular))
              .lineLimit(1)
          }
          .if(mode == .details) { $0.font(.system(size: 20)) }
          .truncationMode(.tail)
          .lineLimit(1)
      }
      .foregroundColor(Color.primary)
      .padding(.trailing, 9)
      .padding(.leading, 12)
      .if(mode == .details) { $0.padding(.bottom, 6).padding(.horizontal, 20) }
    }
    .frame(height: 54)
    .listRowInsets(.init(top: 3, leading: 0, bottom: 3, trailing: 0))
    .contentShape(Rectangle())
    .swipeActions(edge: .trailing) {
      Button(role: .destructive) {
        MailController.shared.deleteEmails([email])
      } label: {
        Label("trash", systemImage: "trash")
      }
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
    .contextMenu {
      Text("MOVE TO BUNDLE")
      ForEach(bundles, id: \.objectID) { bundle in
        Button(bundle.name) {
          do {
            try withAnimation {
              try MailController.shared.moveEmail(email, fromBundle: selectedBundle!, toBundle: bundle)
            }
            appAlert.show(message: "moved to \(bundle.name)", icon: "checkmark", delay: 1)
          }
          catch {
            appAlert.show(message: "failed to move message", icon: "xmark", delay: 1)
          }
        }
      }
    }
  }
  
}

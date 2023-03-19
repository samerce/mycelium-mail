import SwiftUI
import Combine


struct EmailThreadView: View {
  var thread: EmailThread
  var isPreview = false
  
  @ObservedObject var navCtrl = NavController.shared
  @State var keyboardHeight: CGFloat = 0
  
  var bottomInset: CGFloat {
    keyboardHeight.isZero
    ? AppSheetDetents.min + safeAreaInsets.bottom
    : keyboardHeight
  }
  var rowInsets: EdgeInsets {
    isPreview
    ? .init()
    : .init(top: 0, leading: 9, bottom: 12, trailing: 9)
  }
  
  // MARK: - VIEW
  
  var body: some View {
    List {
      if isPreview {
        Message(email: thread.lastReceivedEmail, isPreview: true)
          .listRowInsets(rowInsets)
      } else {
        ForEach(thread.emails, id: \.id) { email in
          Message(email: email)
            .listRowInsets(rowInsets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .cornerRadius(12)
            .contextMenu {
              Button {
                Task { await deleteEmail(email) }
              } label: {
                Label("delete", systemImage: "trash")
              }
            }
        }
      }
    }
    .listStyle(.plain)
    .toolbar(.hidden, for: .navigationBar)
    .safeAreaInset(edge: .top) {
      TitleBar
    }
    .safeAreaInset(edge: .bottom) {
      Spacer().frame(height: bottomInset)
    }
    .ignoresSafeArea()
    .onReceive(Publishers.keyboardHeight) { keyboardHeight in
      self.keyboardHeight = keyboardHeight
    }
  }
  
  var TitleBar: some View {
    Text(thread.subject)
      .font(.system(size: 15, weight: .semibold))
      .padding(.top, isPreview ? 12 : safeAreaInsets.top)
      .padding(.bottom, 12)
      .padding(.horizontal, 12)
      .ignoresSafeArea()
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.center)
      .background(OverlayBackgroundView())
  }
  
  func deleteEmail(_ email: Email) async {
    do {
      if thread.emails.count == 1 {
        navCtrl.goBack(withSheet: .inbox)
        try await thread.moveToTrash()
      } else {
        try await email.moveToTrash()
      }
      PersistenceController.shared.save()
    }
    catch {
      print("error deleting email or thread: \(error.localizedDescription)")
      // TODO: UX
    }
  }
  
}


struct Message: View {
  var email: Email
  var isPreview: Bool = false
  
  @State var html = ""
  @State var seenTimer: Timer?
  @State var htmlHeight: CGFloat = 0.0
  @State var showingFromDetails = false
  
  var fromLine: String {
    (showingFromDetails || isPreview)
    ? email.from.address
    : email.fromLine
  }
  
  // MARK: -
  
  var body: some View {
    ZStack {
      if html.isEmpty {
        ProgressView()
          .controlSize(.large)
          .frame(maxWidth: .infinity)
      }
      else { Content }
    }
    .task {
      try? await email.fetchHtml() // TODO: handle error
      html = email.html // TODO: why is this local state necessary?
      
      let indexWhereReplyStarts = html.firstMatch(
        // TODO: make this way more robust
        of: /(<blockquote|<div class="gmail_quote|<div class="zmail_extra|<div class="moz-cite-prefix)/
      )?.range.lowerBound.utf16Offset(in: html) ?? 0
      
      if indexWhereReplyStarts > 0 {
        html = String(html.dropLast(html.count - indexWhereReplyStarts))
        html = String(html.trimmingPrefix(/<br >/))
        html = html.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
  }
  
  var Content: some View {
    VStack(spacing: 0) {
      HStack(alignment: .lastTextBaseline, spacing: 0) {
        Text(fromLine)
          .font(.system(size: 13, weight: .medium))
          .frame(maxWidth: .infinity, alignment: .leading)
          .lineLimit(1)
        
        Text(email.displayDate ?? "")
          .font(.system(size: 13))
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(OverlayBackgroundView(blurStyle: .systemMaterial))
      .onTapGesture {
        showingFromDetails.toggle()
      }
      
      Html
    }
  }
  
  var Html: some View {
    WebView(html: html, height: $htmlHeight)
      .background(Color(.systemBackground))
      .onAppear {
        markEmailSeen()
      }
      .onDisappear {
        seenTimer?.invalidate()
        seenTimer = nil
      }
      .height(htmlHeight)
  }
  
  func markEmailSeen() {
    guard !isPreview else { return }
    
    seenTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
      seenTimer = nil
      
      Task {
        do {
          try await email.markSeen()
        }
        catch {
          // tell person about error
        }
      }
    }
  }
  
}


/// https://developer.apple.com/forums/thread/677823
extension String {
  func htmlToAttributedString() throws -> AttributedString {
    let nsString = try NSAttributedString(data: self.data(using: .utf8)!,
                                   options: [.documentType: NSAttributedString.DocumentType.html],
                                   documentAttributes: nil)
    return AttributedString(nsString)
  }
}

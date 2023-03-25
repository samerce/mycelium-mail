import SwiftUI
import Combine


private var dataCtrl = PersistenceController.shared


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
  
  // MARK: - VIEW
  
  var body: some View {
    List {
      if isPreview {
        MessageRow(email: thread.lastReceivedEmail, isPreview: true)
      } else {
        ForEach(thread.emails, id: \.id) { email in
          MessageRow(email: email)
            .padding(.bottom, 12)
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
      dataCtrl.save()
    }
    catch {
      print("error deleting email or thread: \(error.localizedDescription)")
      // TODO: UX
    }
  }
  
}


private struct MessageRow: View {
  var email: Email
  var isPreview: Bool = false
  
  @State var seenTimer: Timer?
  @State var showingFromDetails = false
  
  var fromLine: String {
    (showingFromDetails || isPreview)
    ? email.from.address
    : email.fromLine
  }
  
  var isSolo: Bool {
    email.thread.emails.count == 1
  }
  
  // MARK: -
  
  var body: some View {
    VStack(spacing: 0) {
      if (!isSolo || isPreview) {
        SenderLine
      }
      
      MessageView(email: email)
        .cornerRadius(isSolo ? 0 : 12)
        .onAppear {
          markEmailSeen()
        }
        .onDisappear {
          seenTimer?.invalidate()
          seenTimer = nil
        }
    }
    .listRowInsets(.init())
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
    .padding(.horizontal, isSolo ? 0 : 9)
  }
  
  var SenderLine: some View {
    HStack(alignment: .lastTextBaseline, spacing: 0) {
      Text(fromLine)
        .font(.system(size: 13, weight: .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
      
      Text(email.displayDate ?? "")
        .font(.system(size: 13))
    }
    .foregroundColor(.secondary)
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .contentShape(Rectangle())
    .onTapGesture {
      showingFromDetails.toggle()
    }
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

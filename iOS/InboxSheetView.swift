import SwiftUI


private let ToolbarHeight = 22.0


struct InboxSheetView: View {
  @ObservedObject var sheetCtrl = AppSheetController.shared
  
  var percentToMid: CGFloat { sheetCtrl.percentToMid }
  var toolbarHeight: CGFloat {
    ToolbarHeight - (ToolbarHeight * percentToMid)
  }
  
  // MARK: - View
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      DragSheetIcon()
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
      
      Text("psymail")
        .font(.system(size: 27, weight: .black))
        .frame(height: 50 * percentToMid)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 18 * percentToMid)
        .opacity(Double(percentToMid))
        .clipped()
      
      BundleTabBarView()
        .clipped()
        .offset(y: 6)
      
      Divider()
        .frame(height: DividerHeight)
        .padding(.horizontal, 9)
        .padding(.bottom, 6)

      Toolbar
      
//      ScrollView {
//        MailboxSection
//          .padding(.bottom, 18)
//        AppSection
//      }
//      .padding(0)
    }
    .frame(maxHeight: .infinity, alignment: .top)
  }
  
  
  private func tabBarHeight(_ parentSize: CGSize) -> CGFloat {
    return 90 * percentToMid
  }
  
  
  private let DividerHeight: CGFloat = 12
  private let allMailboxesIconSize: CGFloat = 22
  private let composeIconSize: CGFloat = 22
  @AppStorage("lastUpdated") var lastUpdatedString: String = Date.distantPast.ISO8601Format()
  @ObservedObject var mailCtrl = MailController.shared
  
  var lastUpdated: Date {
    try! Date(lastUpdatedString, strategy: .iso8601)
  }
  var updatedText: String {
    let durationSinceLastUpdate = Date.now.timeIntervalSince(lastUpdated)
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute]
    if let duration = formatter.string(from: durationSinceLastUpdate) {
      if durationSinceLastUpdate < 60 {
        return "updated just now"
      }
      if durationSinceLastUpdate >= 60 && durationSinceLastUpdate < 120 {
        return "updated 1 min ago"
      }
      return "updated \(duration) mins ago"
    }
    else {
      return "updated ages ago"
    }
  }
  
  private var Toolbar: some View {
    return VStack(alignment: .center, spacing: 0) {
      HStack(spacing: 0) {
        Button(action: loginWithGoogle) {
          ZStack {
            Image(systemName: "line.3.horizontal.decrease.circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.psyAccent)
              .frame(width: allMailboxesIconSize, height: allMailboxesIconSize)
              .font(.system(size: allMailboxesIconSize, weight: .light))
          }.frame(minWidth: 54, maxWidth: .infinity, alignment: .leading)
        }.frame(width: 54, height: 50, alignment: .leading)
        
        TimelineView(.everyMinute) { _ in
          Text(mailCtrl.fetching ? "checking for mail..." : updatedText)
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .opacity(Double(1 - percentToMid))
            .multilineTextAlignment(.center)
            .clipped()
        }
        
        Button { sheetCtrl.sheet = .bundleSettings } label: {
          ZStack {
            Image(systemName: "square.and.pencil")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.psyAccent)
              .frame(width: composeIconSize, height: composeIconSize)
              .font(.system(size: composeIconSize, weight: .light))
          }
          .frame(minWidth: 54, maxHeight: .infinity, alignment: .trailing)
          .contentShape(Rectangle())
        }.frame(width: 54, height: 50, alignment: .leading)
      }
      .frame(height: toolbarHeight)
    }
    .padding(.horizontal, 24)
    .opacity(Double(1 - percentToMid))
  }
  
  
  private var MailboxSection: some View {
    VStack(spacing: 18) {
      HStack(spacing: 0) {
        Text("MAILBOXES")
          .font(.system(size: 14, weight: .light))
          .foregroundColor(Color(.gray))
        
        Spacer()
        
        Button(action: {}) {
          ZStack {
            Image(systemName: "gear")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.psyAccent)
              .font(.system(size: 16, weight: .light))
          }
          .frame(width: 20, alignment: .trailing)
        }
      }
      
      Mailbox("samerce@gmail.com")
      Mailbox("bubbles@expressyouryes.org")
      Mailbox("petals@expressyouryes.org")
    }
    .padding(.horizontal, 18)
    .clipped()
  }
  
  
  private var AppSection: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("APP")
        .font(.system(size: 14, weight: .light))
        .foregroundColor(Color(.gray))
      
      Mailbox("Settings")
      Mailbox("About")
      Mailbox("Feedback")
      Mailbox("Support Us")
    }
    .padding(.horizontal, 18)
  }
  
  
  private func Mailbox(_ name: String) -> some View {
    Text(name)
      .padding()
      .overlay(RoundedRectangle(cornerRadius: 12.0).stroke(.gray))
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  
  private func header(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 12, weight: .light))
      .foregroundColor(Color(UIColor.systemGray))
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  
  private func loginWithGoogle() {
    AccountController.shared.signIn()
  }
  
}


struct InboxDrawerView_Previews: PreviewProvider {
  static var previews: some View {
    InboxSheetView()
  }
}

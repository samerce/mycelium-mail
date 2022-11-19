import SwiftUI
import DynamicOverlay

private enum Grouping: String, CaseIterable, Identifiable {
    case emailAddress = "address"
//    case contactCard = "contact"
    case subject
    case time

    var id: String { self.rawValue }
}

private let HeaderHeight: CGFloat = 42
private let ToolbarHeight: CGFloat = 18
private let FirstExpandedNotch: CGFloat = 0.5

struct InboxDrawerView: View {
  @State private var selectedGrouping = Grouping.emailAddress
  @State private var hiddenViewOpacity = 0.0
  @Binding var perspective: String
  @Binding var translationProgress: Double
  
  // MARK: - View
  
  var body: some View {
    let bottomSpace = CGFloat.maximum(6, 42 - (CGFloat(translationProgress) / FirstExpandedNotch) * 42)
//    let hiddenSectionOpacity = translationProgress > 0 ? translationProgress + 0.48 : 0
    let dividerHeight = CGFloat.maximum(0, DividerHeight - (CGFloat(translationProgress) / FirstExpandedNotch) * DividerHeight)
    return VStack(spacing: 0) {
      DrawerCapsule()
        .padding(.top, 6)
        .padding(.bottom, 4)
      
        perspectiveHeader
        
        TabBarView(selection: $perspective, translationProgress: $translationProgress)

        Divider()
          .frame(height: dividerHeight)
          .padding(.horizontal, 24)
        Spacer().frame(height: 6)
        Toolbar
        Spacer().frame(height: bottomSpace)

      ScrollView {
        MailboxSection
          .padding(.bottom, 18)
        AppSection
      }
      .drivingScrollView()
      .padding(0)
    }
    .frame(height: UIScreen.main.bounds.height)
    .background(OverlayBackgroundView())
    .ignoresSafeArea()
  }
  
  private let HeaderBottomPadding: CGFloat = 18
  
  private var perspectiveHeader: some View {
    let heightWhileDragging = (CGFloat(translationProgress) / FirstExpandedNotch) * HeaderHeight
    let height = min(HeaderHeight, max(0, heightWhileDragging))
    
    let bottomPaddingWhileDragging = (CGFloat(translationProgress) / FirstExpandedNotch) * HeaderBottomPadding
    let bottomPadding = min(HeaderBottomPadding, max(0, bottomPaddingWhileDragging))
    let opacity = min(1, max(0, (translationProgress / Double(FirstExpandedNotch)) * 1))
    
    return HStack(spacing: 0) {
      Text("BUNDLES")
        .frame(maxHeight: height, alignment: .leading)
        .font(.system(size: 14, weight: .light))
        .foregroundColor(Color(.gray))
      Spacer()
      Button(action: addPerspective) {
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
    .padding(.horizontal, 18)
    .padding(.bottom, bottomPadding)
    .opacity(opacity)
    .frame(height: height)
    .clipped()
  }
  
  private func addPerspective() {
    
  }
  
  private let DividerHeight: CGFloat = 9
  private let allMailboxesIconSize: CGFloat = 25
  private let composeIconSize: CGFloat = 25
  
  private var Toolbar: some View {
    let height = CGFloat.maximum(0, ToolbarHeight - (CGFloat(translationProgress) / FirstExpandedNotch) * ToolbarHeight)
    let opacity = CGFloat.maximum(0, 1 - (CGFloat(translationProgress) / FirstExpandedNotch))
    return VStack(alignment: .center, spacing: 0) {
      HStack(spacing: 0) {
          Button(action: loginWithGoogle) {
            ZStack {
              Image(systemName: "line.3.horizontal.decrease.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.psyAccent)
                .frame(maxWidth: allMailboxesIconSize, maxHeight: height)
                .font(.system(size: allMailboxesIconSize, weight: .light))
            }.frame(width: 54, height: 50, alignment: .leading)
          }.frame(width: 54, height: 50, alignment: .leading)
        
        Text("updated just now")
          .font(.system(size: 14, weight: .light))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: height)
          .multilineTextAlignment(.center)
          .clipped()
        
        Button(action: {}) {
          ZStack {
            Image(systemName: "square.and.pencil")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.psyAccent)
              .frame(maxWidth: composeIconSize, maxHeight: height)
              .font(.system(size: composeIconSize, weight: .light))
          }.frame(width: 54, height: 50, alignment: .trailing)
        }.frame(width: 54, height: 50, alignment: .leading)
      }
      .frame(height: height)
    }
    .padding(.horizontal, 24)
    .opacity(Double(opacity))
    .clipped()
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
      Mailbox("Donate")
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
  @State static var progress = 0.0
  @State static var perspective = "latest"
  static var previews: some View {
    InboxDrawerView(perspective: $perspective,
                    translationProgress: $progress)
  }
}

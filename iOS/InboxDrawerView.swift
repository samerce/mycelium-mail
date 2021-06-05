import SwiftUI
import DynamicOverlay

private enum Grouping: String, CaseIterable, Identifiable {
    case emailAddress = "address"
//    case contactCard = "contact"
    case subject
    case time

    var id: String { self.rawValue }
}

private let DefaultToolbarHeight: CGFloat = 54.0
private let HeaderHeight: CGFloat = 32
private let ToolbarHeight: CGFloat = 27
private let FirstExpandedNotch: CGFloat = 0.5

struct InboxDrawerView: View {
  @State private var selectedGrouping = Grouping.emailAddress
  @State private var hiddenViewOpacity = 0.0
  @State private var toolbarHeight = DefaultToolbarHeight
  @Binding var selectedTab: Int
  @Binding var translationProgress: Double
  
  // MARK: - View
  
  var body: some View {
    let bottomSpace = CGFloat.maximum(12, 54 - (CGFloat(translationProgress) / FirstExpandedNotch) * 54)
//    let hiddenSectionOpacity = translationProgress > 0 ? translationProgress + 0.48 : 0
    return VStack(spacing: 0) {
      DrawerCapsule()
        .padding(.top, 6)
        .padding(.bottom, 2)
      
      perspectiveHeader
      
      TabBarView(selection: $selectedTab, translationProgress: $translationProgress)

      toolbar
      Spacer().frame(height: bottomSpace)

      ScrollView {
        groupBySection
        Spacer().frame(height: 32)
        filterSection
      }
      .drivingScrollView()
      .padding(0)
    }
    .frame(height: UIScreen.main.bounds.height * 0.92)
    .background(OverlayBackgroundView())
    .ignoresSafeArea()
  }
  
  private let HeaderBottomPadding: CGFloat = 6
  private var perspectiveHeader: some View {
    let height = min(HeaderHeight, max(0, (CGFloat(translationProgress) / FirstExpandedNotch) * HeaderHeight))
    let bottomPadding = min(HeaderBottomPadding, max(0, CGFloat(translationProgress) / FirstExpandedNotch) * HeaderBottomPadding)
    let opacity = min(1, max(0, (translationProgress / Double(FirstExpandedNotch)) * 1))
    
    return HStack(spacing: 0) {
      Text("PERSPECTIVES")
        .frame(maxHeight: height, alignment: .leading)
        .font(.system(size: 12, weight: .light))
        .foregroundColor(Color(.gray))
      Spacer()
      Button(action: addPerspective) {
        ZStack {
          Image(systemName: "plus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 16, maxHeight: .infinity)
            .foregroundColor(.psyAccent)
            .font(.system(size: 12, weight: .light))
        }
        .frame(width: 54, alignment: .trailing)
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
  private let allMailboxesIconSize: CGFloat = 27
  private let composeIconSize: CGFloat = 25
  private var toolbar: some View {
    let height = CGFloat.maximum(0, ToolbarHeight - (CGFloat(translationProgress) / FirstExpandedNotch) * ToolbarHeight)
    let dividerHeight = CGFloat.maximum(0, DividerHeight - (CGFloat(translationProgress) / FirstExpandedNotch) * DividerHeight)
    let opacity = CGFloat.maximum(0, 1 - (CGFloat(translationProgress) / FirstExpandedNotch))
    return VStack(alignment: .center, spacing: 0) {
      Divider().frame(height: dividerHeight)
      Spacer().frame(height: 12)
      
      HStack(spacing: 0) {
          Button(action: loginWithGoogle) {
            ZStack {
              Image(systemName: "tray.2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.psyAccent)
                .frame(maxWidth: allMailboxesIconSize, maxHeight: height)
                .font(.system(size: allMailboxesIconSize, weight: .light))
            }.frame(width: 54, height: 50, alignment: .leading)
          }.frame(width: 54, height: 50, alignment: .leading)
        
        Text("updated just now")
          .font(.system(size: 16, weight: .light))
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
  
  private var groupBySection: some View {
    Section(header: header("GROUPING")) {
      Picker("group by", selection: $selectedGrouping) {
        ForEach(Grouping.allCases) { grouping in
          Text(grouping.rawValue)
            .font(.system(size: 14))
            .foregroundColor(Color(.darkGray))
        }
      }
      .pickerStyle(SegmentedPickerStyle())
    }
    .padding(.horizontal, 18)
  }
  
  private var filterSection: some View {
    Section(header: header("FILTERS")) {
      FilterView()
    }
    .padding(.horizontal, 18)
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
  @State static var selectedTab = 0
  static var previews: some View {
    InboxDrawerView(selectedTab: $selectedTab,
                    translationProgress: $progress)
  }
}

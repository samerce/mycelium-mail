import SwiftUI
import DynamicOverlay

enum Grouping: String, CaseIterable, Identifiable {
    case emailAddress = "email"
    case contactCard = "contact"
    case subject
    case time

    var id: String { self.rawValue }
}

let DefaultToolbarHeight: CGFloat = 54.0
let HeaderHeight: CGFloat = 27
let ToolbarHeight: CGFloat = 27
let FirstExpandedNotch: CGFloat = 0.5

struct InboxDrawerView: View {
  @State private var selectedGrouping = Grouping.emailAddress
  @State private var hiddenViewOpacity = 0.0
  @State private var toolbarHeight = DefaultToolbarHeight
  @Binding var selectedTab: Int
  @Binding var translationProgress: Double
  
  // MARK: - View
  
  var body: some View {
    let bottomSpace = CGFloat.maximum(27, 54 - (CGFloat(translationProgress) / FirstExpandedNotch) * 54)
//    let hiddenSectionOpacity = translationProgress > 0 ? translationProgress + 0.48 : 0
    return VStack(spacing: 0) {
      DrawerCapsule()
        .padding(.top, 6)
      
      perspectiveHeader
      Spacer().frame(height: 12)
      
      TabBarView(selection: $selectedTab, translationProgress: $translationProgress)

      toolbar
      Spacer().frame(height: bottomSpace)

      ScrollView {
        groupBySection
        Spacer().frame(height: 27)
        filterSection
      }
      .drivingScrollView()
      .padding(0)
    }
    .frame(height: UIScreen.main.bounds.height * 0.92)
    .background(OverlayBackgroundView())
    .ignoresSafeArea()
  }
  
  private var perspectiveHeader: some View {
    let height = CGFloat.minimum(HeaderHeight, CGFloat.maximum(0, (CGFloat(translationProgress) / FirstExpandedNotch) * HeaderHeight))
    let opacity = CGFloat.minimum(1, CGFloat.maximum(0, (CGFloat(translationProgress) / FirstExpandedNotch) * 1))
    return HStack(spacing: 0) {
      Text("PERSPECTIVES")
        .frame(maxWidth: .infinity, maxHeight: height, alignment: .leading)
        .font(.system(size: 12, weight: .light, design: .default))
        .foregroundColor(Color(UIColor.gray))
        .clipped()
      Spacer()
        Button(action: addPerspective) {
          Image(systemName: "plus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: height)
            .foregroundColor(.pink)
            .font(.system(size: 12, weight: .light, design: .default))
        }
        .clipped()
        .cornerRadius(12)
    }
    .padding(.horizontal, 18)
    .opacity(Double(opacity))
    .frame(height: height)
    .clipped()
  }
  
  private func addPerspective() {
    
  }
  
  private var toolbar: some View {
    let height = CGFloat.maximum(0, ToolbarHeight - (CGFloat(translationProgress) / FirstExpandedNotch) * ToolbarHeight)
    let dividerHeight = CGFloat.maximum(0, 18 - (CGFloat(translationProgress) / FirstExpandedNotch) * 18)
    let opacity = CGFloat.maximum(0, 1 - (CGFloat(translationProgress) / FirstExpandedNotch))
    let iconSize: CGFloat = 27
    return VStack(alignment: .center, spacing: 0) {
      Divider().frame(height: dividerHeight)
      HStack(spacing: 0) {
          Button(action: loginWithGoogle) {
            ZStack {
              Image(systemName: "wand.and.stars.inverse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.pink)
                .frame(maxWidth: iconSize, maxHeight: height)
                .font(.system(size: iconSize, weight: .light))
            }.frame(width: 54, height: 50, alignment: .leading)
          }
        
        Text("updated just now")
          .font(.system(size: 16, weight: .light, design: .rounded))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: height)
          .multilineTextAlignment(.center)
          .clipped()
        
        Button(action: {}) {
          ZStack {
            Image(systemName: "square.and.pencil")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.pink)
              .frame(maxWidth: iconSize, maxHeight: height)
              .font(.system(size: iconSize, weight: .light))
          }.frame(width: 54, height: 50, alignment: .trailing)
        }
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
        }
      }
      .pickerStyle(SegmentedPickerStyle())
    }
    .padding(.horizontal, 18)
  }
  
  private var filterSection: some View {
    Section(header: header("FILTERS")) {
      VStack {
        ForEach(0..<20) { i in
          Text("Filter")
        }
      }
    }
    .padding(.horizontal, 18)
  }
  
  private func header(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 12, weight: .light, design: .default))
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

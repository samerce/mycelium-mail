import SwiftUI


struct TabRow: Identifiable {
  var label: String
  var icon: String
  var id: String { label }
}

let TabConfig = [
  [
    TabRow(label: "notifications", icon: "bell"),
    TabRow(label: "commerce", icon: "creditcard"),
    TabRow(label: "everything", icon: "tray.full"),
    TabRow(label: "newsletters", icon: "newspaper"),
    TabRow(label: "society", icon: "building.2")
  ],
  [
    TabRow(label: "marketing", icon: "megaphone"),
    TabRow(label: "DMs", icon: "person.2"),
    TabRow(label: "news", icon: "network"),
    TabRow(label: "events", icon: "calendar"),
    TabRow(label: "packages", icon: "shippingbox")
  ],
  [
    TabRow(label: "trash", icon: "trash"),
    TabRow(label: "folders", icon: "folder"),
    TabRow(label: "sent", icon: "paperplane"),
  ]
]


private let TabBarHeight = 42.0
private let SpacerHeight = 18.0
private let TranslationMax = 108.0
private let HeaderHeight: CGFloat = 42
private let HeaderBottomPadding: CGFloat = 18

struct BundleTabBarView: View {
  @Binding var selection: String
  @Binding var translationProgress: Double
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      ForEach(Array(TabConfig.enumerated()), id: \.0) { rowIndex, tabRow in
        let tabRowHeight = heightForTabRow(rowIndex)
        let tabRowOpacity = opacityForTabRow(rowIndex)
        
//        Text(String(tabRow.count))
        
        HStack(alignment: .lastTextBaseline) {
          Spacer()
          
          ForEach(Array(tabRow.enumerated()), id: \.0) { index, item in
//            Text(String(item.label))
            TabBarItem(
              iconName: item.icon,
              label: item.label,
              selected: selection == item.label,
              translationProgress: $translationProgress
            )
            .frame(maxHeight: .infinity)
            .clipped()
            .onTapGesture { selection = item.label }
          }
          
          Spacer()
        }
        .frame(height: tabRowHeight)
        .opacity(tabRowOpacity)
        
        Spacer().frame(height: spacerHeight)
      }
    }
  }
  
  private var heightWhileDragging: CGFloat {
    (CGFloat(translationProgress) / inboxSheetDetents.mid) * HeaderHeight
  }
  private var headerHeight: CGFloat {
    min(HeaderHeight, max(0, heightWhileDragging))
  }
  private var bottomPaddingWhileDragging: CGFloat {
    (CGFloat(translationProgress) / inboxSheetDetents.mid) * HeaderBottomPadding
  }
  private var bottomPadding: CGFloat {
    min(HeaderBottomPadding, max(0, bottomPaddingWhileDragging))
  }
  private var opacity: CGFloat {
    min(1, max(0, (translationProgress / Double(inboxSheetDetents.mid)) * 1))
  }
  
  private var BundleHeader: some View {
    HStack(spacing: 0) {
      Text("BUNDLES")
        .frame(maxHeight: headerHeight, alignment: .leading)
        .font(.system(size: 14, weight: .light))
        .foregroundColor(Color(.gray))
      Spacer()
      Button(action: onClickBundleSettings) {
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
    .frame(height: headerHeight)
    .clipped()
  }
  
  private func onClickBundleSettings() {
    
  }
  
  private func heightForTabRow(_ row: Int) -> CGFloat {
    let heightWhileDragging = (CGFloat(translationProgress) / TranslationMax) * TabBarHeight
    let variableTabBarHeight = min(TabBarHeight, max(0, heightWhileDragging))
    
    return row == rowWithActiveTab ? TabBarHeight : variableTabBarHeight
  }
  
  private func opacityForTabRow(_ row: Int) -> Double {
    let variableOpacity = min(1, max(0, (translationProgress / TranslationMax) * 1))
    return row == rowWithActiveTab ? 1 : variableOpacity
  }
  
  private var spacerHeight: CGFloat {
    min(SpacerHeight, max(0, (CGFloat(translationProgress) / TranslationMax) * SpacerHeight))
  }
  
  private var rowWithActiveTab: Int {
    for (rowIndex, tabRowItems) in TabConfig.enumerated() {
      for item in tabRowItems {
        if item.label == selection {
          return rowIndex
        }
      }
    }
    return -1
  }
  
}

struct TabBarView_Previews: PreviewProvider {
  @State static var selectedTab = "latest"
  @State static var translationProgress: Double = 0
  static var previews: some View {
    BundleTabBarView(selection: $selectedTab, translationProgress: $translationProgress)
  }
}

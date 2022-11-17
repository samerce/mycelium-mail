import SwiftUI

struct TabRow: Identifiable {
  var label: String
  var icon: String
  
  var id: String { label }
}

let TabConfig = [
  [
    TabRow(label: "events", icon: "calendar"),
    TabRow(label: "commerce", icon: "creditcard"),
    TabRow(label: "everything", icon: "infinity"),
    TabRow(label: "digests", icon: "newspaper"),
    TabRow(label: "DMs", icon: "person.2")
  ],
  [
    TabRow(label: "marketing", icon: "megaphone"),
    TabRow(label: "society", icon: "building.2"),
    TabRow(label: "news", icon: "network"),
    TabRow(label: "notifications", icon: "bell"),
    TabRow(label: "packages", icon: "shippingbox")
  ],
//  [
//    (label: "trash", icon: "trash"),
//    (label: "folders", icon: "folder"),
//    (label: "sent", icon: "paperplane"),
//  ]
]

private let TabBarHeight: CGFloat = 54
private let SpacerHeight: CGFloat = 18

struct TabBarView: View {
  @Binding var selection: String
  @Binding var translationProgress: Double
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      ForEach(0..<TabConfig.count) { rowIndex in
        let tabRowHeight = heightForTabRow(rowIndex)
        let tabRowOpacity = opacityForTabRow(rowIndex)
        HStack(alignment: .lastTextBaseline) {
          Spacer()
          
          ForEach(TabConfig[rowIndex], id: \.label) { item in
            TabBarItem(
              iconName: item.icon,
              label: item.label,
              selected: selection == item.label,
              translationProgress: $translationProgress
            )
            .frame(height: tabRowHeight)
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
  
  private func heightForTabRow(_ row: Int) -> CGFloat {
    let variableTabBarHeight =
      min(TabBarHeight, max(0, (CGFloat(translationProgress) / 0.5) * TabBarHeight))
    
    return row == rowForSelection ? TabBarHeight : variableTabBarHeight
  }
  
  private func opacityForTabRow(_ row: Int) -> Double {
    let variableOpacity = min(1, max(0, (translationProgress / 0.5) * 1))
    return row == rowForSelection ? 1 : variableOpacity
  }
  
  private var spacerHeight: CGFloat {
    min(SpacerHeight, max(0, (CGFloat(translationProgress) / 0.5) * SpacerHeight))
  }
  
  private var rowForSelection: Int {
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
    TabBarView(selection: $selectedTab, translationProgress: $translationProgress)
  }
}

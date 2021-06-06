import SwiftUI

struct TabBarView: View {
  @Binding var selection: Int
  @Binding var translationProgress: Double
  
  let TabBarHeight: CGFloat = 54
  let SpacerHeight: CGFloat = 18
  var body: some View {
    let spacerHeight = min(SpacerHeight, max(0, (CGFloat(translationProgress) / 0.5) * SpacerHeight))
    let variableTabBarHeight = min(TabBarHeight, max(0, (CGFloat(translationProgress) / 0.5) * TabBarHeight))
    let variableOpacity = min(1, max(0, (translationProgress / 0.5) * 1))
    
    var topTabBarHeight = TabBarHeight
    var bottomTabBarHeight = TabBarHeight
    var topBarOpacity: Double = 1
    var bottomBarOpacity: Double = 1
    if selection < 5 {
      bottomTabBarHeight = variableTabBarHeight
      bottomBarOpacity = variableOpacity
    } else {
      topTabBarHeight = variableTabBarHeight
      topBarOpacity = variableOpacity
    }
    
    return VStack(alignment: .center, spacing: 0) {
      HStack(alignment: .lastTextBaseline) {
        Spacer()
        TabBarItem(iconName: "building.2",
                   label: "society",
                   tag: 0,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "calendar",
                   label: "events",
                   tag: 1,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "newspaper",
                   label: "digests",
                   tag: 2,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "creditcard",
                   label: "commerce",
                   tag: 3,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "person.2",
                   label: "DMs",
                   tag: 4,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: topTabBarHeight)
          .clipped()
        Spacer()
      }
      .frame(height: topTabBarHeight)
      .opacity(topBarOpacity)
      
      Spacer().frame(height: spacerHeight)
      
      HStack(alignment: .lastTextBaseline) {
        Spacer()
        TabBarItem(iconName: "megaphone",
                   label: "marketing",
                   tag: 5,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "heart",
                   label: "health",
                   tag: 6,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "network",
                   label: "news",
                   tag: 7,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "bell.badge",
                   label: "notifications",
                   tag: 8,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "infinity",
                   label: "everything",
                   tag: 9,
                   selection: $selection,
                   translationProgress: $translationProgress)
          .frame(height: bottomTabBarHeight)
          .clipped()
        
        Spacer()
      }
      .frame(height: bottomTabBarHeight)
      .opacity(bottomBarOpacity)
    }
  }
  
}

struct TabBarView_Previews: PreviewProvider {
  @State static var selectedTab = 0
  @State static var translationProgress: Double = 0
  static var previews: some View {
    TabBarView(selection: $selectedTab, translationProgress: $translationProgress)
  }
}

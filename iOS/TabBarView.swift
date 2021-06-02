//
//  ContentView.swift
//  SwiftUICustomTabBar
//
//  Created by Arda Tugay on 12/12/19.
//  Copyright © 2019 ardatugay. All rights reserved.
//

import SwiftUI

struct TabBarView: View {
  @Binding var selection: Int
  @Binding var translationProgress: Double
  
  let TabBarHeight: CGFloat = 48
  let SpacerHeight: CGFloat = 27
  var body: some View {
    let spacerHeight = CGFloat.minimum(SpacerHeight, CGFloat.maximum(0, (CGFloat(translationProgress) / 0.5) * SpacerHeight))
    let variableTabBarHeight = CGFloat.minimum(TabBarHeight, CGFloat.maximum(0, (CGFloat(translationProgress) / 0.5) * TabBarHeight))
    let variableOpacity = CGFloat.minimum(1, CGFloat.maximum(0, (CGFloat(translationProgress) / 0.5) * 1))
    
    var topTabBarHeight = TabBarHeight
    var bottomTabBarHeight = TabBarHeight
    var topBarOpacity:CGFloat = 1
    var bottomBarOpacity:CGFloat = 1
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
        TabBarItem(iconName: "person",
                   label: "DMs",
                   selection: $selection,
                   tag: 0)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "calendar",
                   label: "events",
                   selection: $selection,
                   tag: 1)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "book",
                   label: "digests",
                   selection: $selection,
                   tag: 2)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "creditcard",
                   label: "commerce",
                   selection: $selection,
                   tag: 3)
          .frame(height: topTabBarHeight)
          .clipped()
        TabBarItem(iconName: "building.2",
                   label: "society",
                   selection: $selection,
                   tag: 4)
          .frame(height: topTabBarHeight)
          .clipped()
        
        Spacer()
      }
      .frame(height: topTabBarHeight)
      .opacity(Double(topBarOpacity))
      
      Spacer().frame(height: spacerHeight)
      
      HStack(alignment: .lastTextBaseline) {
        Spacer()
        TabBarItem(iconName: "megaphone",
                   label: "marketing",
                   selection: $selection,
                   tag: 5)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "newspaper",
                   label: "news",
                   selection: $selection,
                   tag: 6)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "bell.badge",
                   label: "notifications",
                   selection: $selection,
                   tag: 7)
          .frame(height: bottomTabBarHeight)
          .clipped()
        TabBarItem(iconName: "infinity",
                   label: "everything",
                   selection: $selection,
                   tag: 8)
          .frame(height: bottomTabBarHeight)
          .clipped()
        
        Spacer()
      }
      .frame(height: bottomTabBarHeight)
      .opacity(Double(bottomBarOpacity))
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

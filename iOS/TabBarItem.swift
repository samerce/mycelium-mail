//
//  CustomTabBarItem.swift
//  SwiftUICustomTabBar
//
//  Created by Arda Tugay on 12/13/19.
//  Copyright © 2019 ardatugay. All rights reserved.
//

import SwiftUI

struct TabBarItem: View {
    let iconName: String
    let label: String
    let selection: Binding<Int>
    let tag: Int
    
    init(iconName: String,
         label: String,
         selection: Binding<Int>,
         tag: Int) {
        self.iconName = iconName
        self.label = label
        self.selection = selection
        self.tag = tag
    }
    
    var body: some View {
      VStack(alignment: .center) {
        Image(systemName: iconName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 27, height: 27)
          .font(.system(size: 27, weight: .light, design: .default))
        Text(label)
            .font(.caption)
      }
      .frame(maxWidth: .infinity)
      .foregroundColor(fgColor())
      .contentShape(Rectangle())
      .onTapGesture { self.selection.wrappedValue = self.tag }
      
//      if selection.wrappedValue == tag {
//        return AnyView(rainbowGradientVertical.mask(inner))
//      } else {
//        return AnyView(inner)
//      }
    }
    
    private func fgColor() -> Color {
      return selection.wrappedValue == tag ? Color(.green) : Color(.secondaryLabel)
    }
}

struct TabBarItem_Previews: PreviewProvider {
    static var selection: Int = 0
    static var selectionBinding = Binding<Int>(get: { selection }, set: { selection = $0 })
    
    static var previews: some View {
        TabBarItem(
          iconName: "clock.fill",
          label: "Recents",
          selection: selectionBinding,
          tag: 0)
        .previewLayout(.fixed(width: 80, height: 80))
    }
}

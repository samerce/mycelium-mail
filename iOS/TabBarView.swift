//
//  ContentView.swift
//  SwiftUICustomTabBar
//
//  Created by Arda Tugay on 12/12/19.
//  Copyright © 2019 ardatugay. All rights reserved.
//

import SwiftUI

struct TabBarView: View {
  @State private var selection: Int = 0
  
  enum Event {
    case didTapTab
  }
  
  let eventHandler: (Event) -> Void
  
  var body: some View {
    HStack(alignment: .lastTextBaseline) {
      TabBarItem(iconName: "person",
                       label: "DMs",
                       selection: $selection,
                       tag: 0)
      TabBarItem(iconName: "calendar",
                       label: "events",
                       selection: $selection,
                       tag: 1)
      TabBarItem(iconName: "book",
                       label: "digests",
                       selection: $selection,
                       tag: 2)
      TabBarItem(iconName: "creditcard",
                       label: "commerce",
                       selection: $selection,
                       tag: 3)
      TabBarItem(iconName: "building.2",
                       label: "society",
                       selection: $selection,
                       tag: 4)
    }
    .frame(maxHeight: .infinity, alignment: .bottom)
  }
  
}

struct TabBarView_Previews: PreviewProvider {
  static var previews: some View {
    TabBarView { event in
      
    }
  }
}

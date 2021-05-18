//
//  OverlayView.swift
//  DynamicOverlay_Example
//
//  Created by Gaétan Zanella on 17/04/2021.
//  Copyright © 2021 Fabernovel. All rights reserved.
//

import Foundation
import SwiftUI
import DynamicOverlay
import GoogleSignIn

enum Grouping: String, CaseIterable, Identifiable {
    case emailAddress = "email"
    case contactCard = "contact"
    case subject
    case time

    var id: String { self.rawValue }
}

struct InboxDrawerView: View {
  @State private var selectedGrouping = Grouping.emailAddress
  @State private var hiddenViewOpacity = 0.0
  @Binding var selectedTab: Int
  @Binding var translationProgress: Double
  
  enum Event {
    case didTapTab
  }
  
  let eventHandler: (Event) -> Void
  
  // MARK: - View
  
  var body: some View {
    let hiddenSectionOpacity = translationProgress > 0 ? translationProgress + 0.48 : 0
    VStack(alignment: .center, spacing: 18) {
      Capsule()
        .fill(Color(UIColor.darkGray))
        .frame(width: 36, height: 5, alignment: .center)
        .padding(.top, 6)
        .padding(.bottom, -12)
      
      TabBarView(selection: $selectedTab) { event in
        switch event {
        case .didTapTab:
          eventHandler(.didTapTab)
        }
      }
      .padding(.horizontal, 9)
      
      ScrollView {
        toolbar
        groupBySection.opacity(hiddenSectionOpacity)
        filterSection.opacity(hiddenSectionOpacity)
      }.drivingScrollView()
    }.background(OverlayBackgroundView())
  }
  
  private var toolbar: some View {
    HStack {
      Button(action: loginWithGoogle) {
        Image(systemName: "wand.and.stars.inverse")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(.blue)
          .frame(width: 27, height: 27)
      }
      Text("updated just now")
        .font(.system(size: 14, weight: .regular, design: .rounded))
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
      Image(systemName: "square.and.pencil")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundColor(.blue)
        .frame(width: 27, height: 27)
    }
    .padding(.horizontal, 18)
  }
  
  private var groupBySection: some View {
    Section(header: header("GROUP BY")) {
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
    Section(header: header("FILTER")) {
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
  
  // MARK: - Private\
  
  private var list: some View {
    List {
      Section(header: Text("Favorites")) {
        ScrollView(.horizontal) {
          HStack {
            FavoriteCell(imageName: "house.fill", title: "House")
            FavoriteCell(imageName: "briefcase.fill", title: "Work")
            FavoriteCell(imageName: "plus", title: "Add")
          }
        }
      }
      Section(header: Text("My Guides")) {
        ActionCell()
      }
    }
    .listStyle(GroupedListStyle())
  }
  
  private func loginWithGoogle() {
    GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.last?.rootViewController
//    GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    GIDSignIn.sharedInstance().signIn()
  }
  
}

struct InboxDrawerView_Previews: PreviewProvider {
  @State static var progress = 0.0
  @State static var selectedTab = 0
  static var previews: some View {
    InboxDrawerView(selectedTab: $selectedTab,
                    translationProgress: $progress) { event in
    }
    .drivingScrollView()
  }
}

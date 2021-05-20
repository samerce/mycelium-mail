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

let DefaultToolbarHeight: CGFloat = 54.0

struct InboxDrawerView: View {
  @State private var selectedGrouping = Grouping.emailAddress
  @State private var hiddenViewOpacity = 0.0
  @State private var toolbarHeight = DefaultToolbarHeight
  @Binding var selectedTab: Int
  @Binding var translationProgress: Double
  
  enum Event {
    case didTapTab
  }
  
  let eventHandler: (Event) -> Void
  
  // MARK: - View
  
  var body: some View {
//    let hiddenSectionOpacity = translationProgress > 0 ? translationProgress + 0.48 : 0
    VStack(alignment: .center, spacing: 0) {
      Capsule()
        .fill(Color(UIColor.darkGray))
        .frame(width: 36, height: 5, alignment: .center)
        .padding(.top, 6)
      
      perspectiveHeader
      Spacer().frame(height: 12)
      
      TabBarView(selection: $selectedTab) { event in
        switch event {
        case .didTapTab:
          eventHandler(.didTapTab)
        }
      }
      .padding(.horizontal, 20)
      
      Spacer().frame(height: 4)
      
      ScrollView {
        toolbar
        Spacer().frame(height: 12)
        groupBySection
        Spacer().frame(height: 18)
        filterSection
      }
      .drivingScrollView()
      .padding(0)
    }
    .background(OverlayBackgroundView())
  }
  
  let HeaderHeight: CGFloat = 27
  private var perspectiveHeader: some View {
    let height = CGFloat.minimum(HeaderHeight, CGFloat.maximum(0, (CGFloat(translationProgress) / 0.5) * HeaderHeight))
    let padding = CGFloat.minimum(-3, CGFloat.maximum(0, (CGFloat(translationProgress) / 0.5) * -3))
    let opacity = CGFloat.minimum(1, CGFloat.maximum(0, (CGFloat(translationProgress) / 0.5) * 1))
    return HStack(alignment: .center, spacing: 0) {
      Text("PERSPECTIVES")
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(size: 12, weight: .light, design: .default))
        .foregroundColor(Color(UIColor.gray))
      Spacer()
      Button(action: addPerspective) {
        Image(systemName: "plus")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(.green)
          .frame(width: 16, height: 16)
          .font(.system(size: 12, weight: .light, design: .default))
      }
      .clipped()
      .cornerRadius(12)
    }
    .animation(.interactiveSpring(), value: translationProgress)
    .padding(.horizontal, 18)
    .opacity(Double(opacity))
    .frame(height: height)
    .clipped()
  }
  
  private func addPerspective() {
    
  }
  
  let ToolbarHeight: CGFloat = 36
  private var toolbar: some View {
    let height = CGFloat.maximum(0, ToolbarHeight - (CGFloat(translationProgress) / 0.50) * ToolbarHeight)
    let dividerHeight = CGFloat.maximum(0, 12 - (CGFloat(translationProgress) / 0.50) * 12)
    let bottomSpace = CGFloat.maximum(0, 54 - (CGFloat(translationProgress) / 0.50) * 54)
    let opacity = CGFloat.maximum(0, 1 - (CGFloat(translationProgress) / 0.50))
    return VStack(alignment: .center, spacing: 0) {
      Divider().frame(height: dividerHeight)
      HStack(alignment: .center) {
        Button(action: loginWithGoogle) {
          Image(systemName: "wand.and.stars.inverse")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.green)
            .frame(maxWidth: 22, maxHeight: .infinity)
            .font(.system(size: 22, weight: .light, design: .default))
        }
        Text("updated just now")
          .font(.system(size: 14, weight: .light, design: .rounded))
          .foregroundColor(.primary)
          .frame(maxWidth: .infinity)
          .multilineTextAlignment(.center)
        Image(systemName: "square.and.pencil")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(.green)
          .frame(maxWidth: 22, maxHeight: .infinity)
          .font(.system(size: 22, weight: .light, design: .default))
      }
      .frame(height: height)
      
      Spacer().padding(0).frame(height: bottomSpace)
    }
    .animation(.interactiveSpring(), value: translationProgress)
    .padding(.horizontal, 22)
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

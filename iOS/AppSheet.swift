import Foundation
import SwiftUI
import SwiftUIKit


struct AppSheet {
  static let firstStart = Self(
    id: "first start",
    detents: [.large],
    initialDetent: .large
  )
  static let downloadingEmails = Self(
    id: "downloading emails",
    detents: [.large],
    initialDetent: .large
  )
  static let inbox = Self(
    id: "inbox tools",
    detents: [
      .height(AppSheetDetents.min),
      .medium,
      .large
    ],
    initialDetent: .height(AppSheetDetents.min)
  )
  static let emailThread = Self(
    id: "email tools",
    detents: [
      .height(AppSheetDetents.min),
      .medium,
      .large
    ],
    initialDetent: .height(AppSheetDetents.min)
  )
  static let createBundle = Self(
    id: "create bundle",
    detents: [.height(272)],
    initialDetent: .height(272)
  )
  static let bundleSettings = Self(
    id: "bundle settings",
    detents: [.medium, .large],
    initialDetent: .medium
  )
  
  var id: String
  var detents: [UndimmedPresentationDetent]
  var initialDetent: PresentationDetent
}


extension AppSheet: Equatable {
  static func == (lhs: AppSheet, rhs: AppSheet) -> Bool {
    lhs.id == rhs.id
  }
}


struct AppSheetDetents {
  static let min: CGFloat = 90
  static let mid: CGFloat = 420
  static let max: CGFloat = 750
  
  var min: CGFloat = 0
  var mid: CGFloat = 0
  var max: CGFloat = 0
}


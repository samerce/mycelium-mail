import Foundation
import SwiftUI

struct AppSheetDetents {
  var min: CGFloat = 0
  var mid: CGFloat = 0
  var max: CGFloat = 0
}

extension View {
  var appSheetDetents: AppSheetDetents {
    AppSheetDetents(
      min: 90.0,
      mid: self.screenHeight / 2,
      max: self.screenHeight
    )
  }
}

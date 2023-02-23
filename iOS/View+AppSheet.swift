import Foundation
import SwiftUI

extension View {
  var appSheetDetents: AppSheetDetents {
    AppSheetDetents(
      min: 90.0,
      mid: self.screenHeight / 2,
      max: self.screenHeight
    )
  }
}

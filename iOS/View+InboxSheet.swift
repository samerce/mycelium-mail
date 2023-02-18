import Foundation
import SwiftUI

struct InboxSheetDetents {
  var min: CGFloat = 0
  var mid: CGFloat = 0
  var max: CGFloat = 0
}

extension View {
  var inboxSheetDetents: InboxSheetDetents {
    InboxSheetDetents(
      min: 90.0,
      mid: self.screenHeight / 2,
      max: self.screenHeight
    )
  }
}

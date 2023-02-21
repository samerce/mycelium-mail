import Foundation
import SwiftUI


class AppAlert: ObservableObject, Equatable {
  static func == (lhs: AppAlert, rhs: AppAlert) -> Bool {
    lhs.message == rhs.message && lhs.icon == rhs.icon
  }
  
  @Published var message: String?
  @Published var icon: String?
  
  func show(message: String, icon: String, duration: TimeInterval = 3, delay: TimeInterval = 0) {
    let _show = {
      withAnimation {
        self.message = message
        self.icon = icon
      }
    }
    
    if delay > 0 {
      Timer.after(delay) { _ in _show() }
    } else {
      _show()
    }
    
    Timer.after(duration) { _ in self.hide() }
  }
  
  func hide() {
    withAnimation {
      message = nil
      icon = nil
    }
  }
}

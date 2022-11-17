import SwiftUI

extension View {
  
  var screenWidth: CGFloat {
    UIScreen.main.bounds.width
  }
  
  var screenHeight: CGFloat {
    UIScreen.main.bounds.height
  }
  
  var safeAreaInsets: UIEdgeInsets {
    UIApplication.shared.windows.first?.safeAreaInsets ?? UIEdgeInsets.zero
  }
  
  var screenHeightSafe: CGFloat {
    self.screenHeight - safeAreaInsets.top - safeAreaInsets.bottom
  }
  
}

import Foundation
import SwiftUI


extension View {
  
  @ViewBuilder
  func scrollProxy(_ proxyBinding: Binding<ScrollViewProxy?>) -> some View {
    ScrollViewReader { proxy in
      self
        .onAppear {
          proxyBinding.wrappedValue = proxy
        }
    }
  }
  
}

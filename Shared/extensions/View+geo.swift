import Foundation
import SwiftUI

extension View {
  @ViewBuilder func geo(_ sizeBinding: Binding<CGSize>) -> some View {
    GeometryReader { geo in
      self
        .onAppear {
          sizeBinding.wrappedValue = geo.size
        }
        .onChange(of: geo.size) { _ in
          sizeBinding.wrappedValue = geo.size
        }
    }
  }
}

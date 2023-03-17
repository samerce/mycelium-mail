import Foundation
import SwiftUI


struct ButtonImage: View {
  var name: String
  var size: CGFloat = 20.0
  var color: Color = .psyAccent
  var weight: Font.Weight = .light
  var hitAreaScale: CGFloat = 1.5
  
  var buttonSize: CGFloat {
    size * hitAreaScale
  }
  
  var body: some View {
    ZStack {
      SystemImage(name: name, size: size, color: color, weight: weight)
    }
    .width(buttonSize)
    .height(buttonSize)
    .contentShape(Rectangle())
  }
  
}

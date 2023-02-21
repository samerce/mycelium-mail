import SwiftUI
import UIKit

struct OverlayBackgroundView: View {

  var blurStyle: UIBlurEffect.Style = .systemChromeMaterial
  
  var body: some View {
    VisualEffectBlur(blurStyle: blurStyle)
      .shadow(color: .black.opacity(0.36), radius: 6)
  }
}

extension View {
  
  func roundedCorners(_ radius: CGFloat, corners: UIRectCorner = .allCorners) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

private struct RoundedCorner: Shape {
  
  var radius: CGFloat = 0.0
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    Path(
      UIBezierPath(
        roundedRect: rect,
        byRoundingCorners: corners,
        cornerRadii: CGSize(width: radius, height: radius)
      )
      .cgPath
    )
  }
}

//
//  OverlayBackgroundView.swift
//  DynamicOverlay_Example
//
//  Created by Gaétan Zanella on 19/04/2021.
//  Copyright © 2021 Fabernovel. All rights reserved.
//

import SwiftUI

struct OverlayBackgroundView: View {
  
  var body: some View {
    VisualEffectBlur(blurStyle: .systemChromeMaterial)
      .shadow(color: Color.black.opacity(0.36), radius: 6)
  }
}

extension View {
  
  func roundedCorners(_ radius: CGFloat, corners: UIRectCorner) -> some View {
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

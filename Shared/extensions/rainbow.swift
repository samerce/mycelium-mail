//
//  multicolor-glow.swift
//  psymail
//
//  Created by bubbles on 5/17/21.
//

import Foundation
import SwiftUI

public var rainbowGradientHorizontal = LinearGradient(
  gradient: Gradient(colors: [.pink, .red, .orange, .yellow, .green, .blue, .purple]),
  startPoint: .leading, endPoint: .trailing
//  center: .center, startRadius: 0.0, endRadius: 27
)

public var rainbowGradientVertical = LinearGradient(
  gradient: Gradient(colors: [.pink, .red, .orange, .yellow, .green, .blue, .purple]),
  startPoint: .top, endPoint: .bottom
//  center: .center, startRadius: 0.0, endRadius: 27
)

extension View {
  func multicolorGlow() -> some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(0..<4) { i in
          Rectangle()
            .fill(rainbowGradientHorizontal)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .mask(self.blur(radius: 108))
            .overlay(self.blur(radius: 54 - CGFloat(i * 54)))
        }
      }
    }
  }
}

struct RainbowBorder: View {

  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .stroke(rainbowGradientHorizontal, lineWidth: 0.5)
  }
  
}

struct RainbowGlow: View {

  var body: some View {
    rainbowGradientHorizontal.mask(RainbowBorder().shadow(color: .black, radius: 20))
//    ZStack {
//      ForEach(0..<2) { i in
//        rainbowGradient.mask(RainbowBorder().shadow(.black))
//      }
//    }
  }
  
}

struct RainbowGlowBorder: View {

  var body: some View {
    RainbowBorder()
    
  }
  
}


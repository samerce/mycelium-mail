//
//  multicolor-glow.swift
//  psymail
//
//  Created by bubbles on 5/17/21.
//

import Foundation
import SwiftUI

var rainbowGradient = AngularGradient(
  gradient: Gradient(colors: [.purple, .pink, .red, .orange, .yellow, .green, .blue]),
  center: .center, startAngle: .zero, endAngle: .degrees(360)
)

struct RainbowBorder: View {

  var body: some View {
    rainbowGradient.mask(
      RoundedRectangle(cornerRadius: 18)
        .fill(Color.clear)
        .border(Color.black, width: 1)
    )
  }
  
}

struct RainbowGlow: View {

  var body: some View {
    rainbowGradient.mask(RainbowBorder().shadow(color: .black, radius: 20))
//    ZStack {
//      ForEach(0..<2) { i in
//        rainbowGradient.mask(RainbowBorder().shadow(.black))
//      }
//    }
  }
  
}

struct RainbowGlowBorder: View {

  var body: some View {
    RainbowBorder().overlay(RainbowGlow())
  }
  
}


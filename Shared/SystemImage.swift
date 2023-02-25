import SwiftUI


struct SystemImage: View {
  var name: String
  var size: CGFloat
  var color: Color = .psyAccent

  var body: some View {
    Image(systemName: name)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .font(.system(size: size, weight: .light, design: .default))
      .foregroundColor(color)
      .frame(width: size, height: size)
      .contentShape(Rectangle())
      .clipped()
  }
}

import SwiftUI


struct SystemImage: View {
  var name: String
  var size: CGFloat = 20.0
  var color: Color = .psyAccent
  var weight: Font.Weight = .light

  var body: some View {
    Image(systemName: name)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .font(.system(size: size, weight: weight, design: .default))
      .foregroundColor(color)
      .frame(width: size, height: size)
      .contentShape(Rectangle())
  }
}

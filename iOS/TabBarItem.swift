import SwiftUI

private let LabelHeight: CGFloat = 18
private let FirstExpandedNotch: CGFloat = 0.5
private let IconSize = 22.0

struct TabBarItem: View {
  let iconName: String
  let label: String
  
  var selected: Bool
  @Binding var translationProgress: Double
  
  private var labelHeight: CGFloat {
    min(LabelHeight, max(0, (CGFloat(translationProgress) / FirstExpandedNotch) * LabelHeight))
  }
  private var labelOpacity: Double {
    min(1, max(0, (translationProgress / 0.5) * 1))
  }
  
  var body: some View {
    VStack(alignment: .center) {
      Image(systemName: iconName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: IconSize, height: IconSize)
        .font(.system(size: IconSize, weight: .light))
        .contentShape(Rectangle())
      Text(label)
        .font(.system(size: 11, weight: .light))
        .frame(height: labelHeight)
        .opacity(labelOpacity)
        .clipped()
    }
    .foregroundColor(fgColor())
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
  }
  
  private func fgColor() -> Color {
    return selected ? .psyAccent : Color(.secondaryLabel)
  }
}

//struct TabBarItem_Previews: PreviewProvider {
//  static var selection: Int = 0
//  static var selectionBinding = Binding<Int>(get: { selection }, set: { selection = $0 })
//
//  static var previews: some View {
//    TabBarItem(
//      iconName: "clock.fill",
//      label: "Recents",
//      selection: selectionBinding,
//      tag: 0,
//      translationProgress: )
//      .previewLayout(.fixed(width: 80, height: 80))
//  }
//}

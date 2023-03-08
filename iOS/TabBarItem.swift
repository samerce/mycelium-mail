import SwiftUI


private let LabelHeight = 18.0
private let IconSize = 22.0


struct TabBarItem: View {
  let iconName: String
  let label: String
  var selected: Bool
  var collapsible: Bool
  var unread: Bool
  
  @ObservedObject var sheetCtrl = AppSheetController.shared
  
  var percentToMid: CGFloat { sheetCtrl.percentToMid }
  var labelHeight: CGFloat {
    LabelHeight * percentToMid
  }
  var labelOpacity: Double {
    collapsible ? 1 : Double(percentToMid)
  }
  var fgColor: Color {
    selected ? .psyAccent : Color(.secondaryLabel)
  }
  
  var body: some View {
    VStack(alignment: .center) {
      ZStack(alignment: .top) {
        Icon
        UnreadIndicator
      }
      .width(IconSize)
      
      Text(label)
        .font(.system(size: 11, weight: .light))
        .frame(height: labelHeight)
        .opacity(labelOpacity)
    }
    .frame(maxWidth: .infinity)
    .foregroundColor(fgColor)
    .contentShape(Rectangle())
  }
  
  var Icon: some View {
    Image(systemName: iconName)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: IconSize, height: IconSize)
      .font(.system(size: IconSize, weight: .light))
      .padding(.top, 2)
  }
  
  var UnreadIndicator: some View {
    HStack {
      Spacer()
      SystemImage(name: "circle.fill", size: 9, color: .psyAccent)
        .offset(x: 4)
        .scaleEffect(unread ? 1 : 0.0001, anchor: .center)
        .animation(.default, value: unread)
    }
  }
  
}

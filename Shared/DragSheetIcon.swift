import SwiftUI

struct DragSheetIcon: View {
  var body: some View {
    Capsule()
      .fill(.tertiary)
      .frame(width: 36, height: 5, alignment: .center)
  }
}

struct DragSheetIcon_Previews: PreviewProvider {
  static var previews: some View {
    DragSheetIcon()
  }
}

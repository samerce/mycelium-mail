import SwiftUI

struct SheetHandle: View {
  var body: some View {
    Capsule()
      .fill(.tertiary)
      .frame(width: 36, height: 5, alignment: .center)
  }
}

struct SheetHandle_Previews: PreviewProvider {
  static var previews: some View {
    SheetHandle()
  }
}

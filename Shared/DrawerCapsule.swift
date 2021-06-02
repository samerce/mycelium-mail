import SwiftUI

struct DrawerCapsule: View {
  var body: some View {
    Capsule()
      .fill(Color(.gray))
      .frame(width: 36, height: 5, alignment: .center)
  }
}

struct DrawerCapsule_Previews: PreviewProvider {
  static var previews: some View {
    DrawerCapsule()
  }
}

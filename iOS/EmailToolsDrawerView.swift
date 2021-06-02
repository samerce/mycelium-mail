import SwiftUI
import DynamicOverlay

private var mailCtrl = MailController.shared

struct EmailToolsDrawerView: View {
  var email: Email?
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      DrawerCapsule()
        .padding(.vertical, 6)
      
      Spacer().frame(height: 9)
      
      HStack {
        Spacer()
        toolbarButton("archivebox")
        toolbarButton("tag")
        toolbarButton("trash")
        toolbarButton("flag")
        toolbarButton("arrowshape.turn.up.left")
        Spacer()
      }
      
      VStack(alignment: .center, spacing: 0) {
        Divider()
          .padding(.top, 12)
          .padding(.bottom, 4)
        
        HStack {
          Button(action: { mailCtrl.deselectEmail() }) {
            SystemImage("mail.stack", size: 27)
          }
          .frame(width: 36, height: 40)
          
          Spacer().frame(width: 6)
          
          Text(email?.displayDate ?? "")
            .frame(maxWidth: .infinity)
            .font(.system(size: 16, weight: .light))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(1)
          
          Spacer().frame(width: 6)
          
          Button(action: {}) {
            SystemImage("square.and.pencil", size: 27)
          }
          .frame(width: 36, height: 40)
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.horizontal, 24)
      .clipped()
    }
    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .topLeading)
    .background(OverlayBackgroundView())
    .ignoresSafeArea()
  }
  
  private func toolbarButton(
    _ name: String, action: @escaping () -> Void = {}
  ) -> some View {
    Button(action: action) {
      SystemImage(name, size: 24)
    }
    .frame(maxWidth: .infinity)
  }
  
  private func SystemImage(_ name: String, size: CGFloat) -> some View {
    Image(systemName: name)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .foregroundColor(.pink)
      .font(.system(size: size, weight: .light, design: .default))
      .frame(width: size, height: size)
      .contentShape(Rectangle())
  }
  
}

struct EmailToolsDrawerView_Previews: PreviewProvider {
  static var previews: some View {
    EmailToolsDrawerView()
  }
}

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
      
      HStack(spacing: 0) {
        toolbarButton("archivebox")
        toolbarButton("tag")
        toolbarButton("trash")
        toolbarButton("flag")
        toolbarButton("arrowshape.turn.up.left")
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 24)
      
      VStack(spacing: 0) {
        Divider()
          .padding(.top, 12)
        
        HStack(spacing: 0) {
          Spacer()
          
          Button(action: { mailCtrl.deselectEmail() }) {
            ZStack {
              SystemImage("mail.stack", size: 27)
            }.frame(width: 54, height: 50, alignment: .leading)
          }
          
          Spacer().frame(width: 9)
          
          Text(email?.longDisplayDate ?? "")
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
            .font(.system(size: 16, weight: .light))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(1)
          
          Spacer().frame(width: 9)
          
          Button(action: {}) {
            ZStack {
              SystemImage("square.and.pencil", size: 27)
            }.frame(width: 54, height: 50, alignment: .trailing)
          }
        }
        .frame(maxWidth: .infinity)
        
        Spacer()
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

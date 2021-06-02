import SwiftUI
import DynamicOverlay

private var mailCtrl = MailController.shared

struct EmailToolsDrawerView: View {
  var email: Email?
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      DrawerCapsule()
      
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
        Divider().frame(height: 24)
        
        HStack {
          toolbarButton("tray", expand: false) { mailCtrl.deselectEmail() }
          Spacer().frame(width: 6)
          
          VStack {
            Text(email?.fromLine ?? "")
              .frame(maxWidth: .infinity)
              .font(.system(size: 18))
              .foregroundColor(.primary)
              .multilineTextAlignment(.center)
              .lineLimit(1)
            
            Text(email?.displayDate.uppercased() ?? "")
              .frame(maxWidth: .infinity)
              .font(.system(size: 14, weight: .light))
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity)
          
          Spacer().frame(width: 6)
          toolbarButton("square.and.pencil", expand: false)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
      }
      .padding(.horizontal, 24)
      .clipped()
    }
    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .topLeading)
    .background(OverlayBackgroundView())
    .ignoresSafeArea()
  }
  
  private func toolbarButton(
    _ name: String, expand: Bool = true, action: @escaping () -> Void = {}
  ) -> some View {
    Button(action: action) {
      Image(systemName: name)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundColor(.pink)
        .font(.system(size: 27, weight: .light, design: .default))
        .frame(width: 27, height: 27)
        .contentShape(Rectangle())
    }
    .if(expand) { view in view.frame(maxWidth: .infinity) }
  }
  
}

struct EmailToolsDrawerView_Previews: PreviewProvider {
  static var previews: some View {
    EmailToolsDrawerView()
  }
}

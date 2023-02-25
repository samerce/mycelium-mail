import SwiftUI


struct AppAlertView: View {
  @EnvironmentObject var appAlertViewModel: AppAlertViewModel
  
  var icon: String? { appAlertViewModel.icon }
  var message: String? { appAlertViewModel.message }
  var visible: Bool { appAlertViewModel.visible }
  
  
  var body: some View {
    VStack(alignment: .center) {
      Icon
      Message
    }
    .animation(.easeInOut, value: appAlertViewModel)
    .foregroundColor(.white)
    .frame(width: 200, height: 200)
    .background(
      OverlayBackgroundView(blurStyle: .systemChromeMaterial)
        .shadow(color: .black.opacity(0.54), radius: 18)
    )
    .border(.white.opacity(0.12), width: 0.27)
    .cornerRadius(12)
    .visible(if: appAlertViewModel.visible)
  }
  
  @ViewBuilder
  var Icon: some View {
    if let icon = icon {
      SystemImage(name: icon, size: 69, color: .white)
    }
    else { EmptyView() }
  }

  @ViewBuilder
  var Message: some View {
    if let message = message {
      Text(message)
        .font(.system(size: 15, weight: .medium))
        .padding(12)
    }
    else { EmptyView() }
  }
  
}


class AppAlertViewModel: ObservableObject, Equatable {
  static func == (lhs: AppAlertViewModel, rhs: AppAlertViewModel) -> Bool {
    lhs.message == rhs.message && lhs.icon == rhs.icon
  }
  
  @Published var message: String?
  @Published var icon: String?
  @Published var visible: Bool = false
  
  func show(message: String, icon: String, duration: TimeInterval = 3, delay: TimeInterval = 0) {
    let _show = {
      withAnimation {
        self.message = message
        self.icon = icon
        self.visible = true
      }
    }
    
    if delay > 0 {
      Timer.after(delay) { _ in _show() }
    } else {
      _show()
    }
    
    Timer.after(duration) { _ in self.hide() }
  }
  
  func hide() {
    withAnimation {
      message = nil
      icon = nil
      visible = false
    }
  }
}

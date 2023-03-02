import SwiftUI


private let cAlertHeight = 54.0
private let cCornerRadius = 18.0
private let cHiddenOffsetY = 108.0


struct AppAlertView: View {
  @ObservedObject var alertCtrl = AppAlertController.shared
  @State var countdownScale = 0.0
  @State var offsetY = cHiddenOffsetY
  @State var opacity = 0.0
  
  var icon: String? { alertCtrl.icon }
  var message: String? { alertCtrl.message }
  var visible: Bool { alertCtrl.visible }
  var duration: TimeInterval { alertCtrl.duration }
  var delay: TimeInterval { alertCtrl.delay }
  var action: (() -> Void)? { alertCtrl.action }
  var actionLabel: String? { alertCtrl.actionLabel }

  
  var body: some View {
    ZStack(alignment: .top) {
      HStack(alignment: .center) {
        Icon
        Message
        ActionButton
      }
      .height(cAlertHeight)
      .padding(.horizontal, 18)
      
      RoundedRectangle(cornerRadius: cCornerRadius)
        .fill(Color.psyAccent)
        .height(1)
        .scaleEffect(x: countdownScale)
    }
    .frame(maxWidth: screenWidth - 54)
    .background(
      OverlayBackgroundView(blurStyle: .systemUltraThinMaterial)
    )
    .cornerRadius(cCornerRadius)
    .offset(y: offsetY)
    .opacity(opacity)
    .onTapGesture { action?() }
    .allowsHitTesting(visible)
    .onChange(of: visible) { _ in
      if visible {
        if delay > 0 {
          Timer.after(delay) { _ in show() }
        } else {
          show()
        }
      } else {
        hide()
      }
    }
  }
  
  @ViewBuilder
  var Icon: some View {
    if let icon = icon {
      SystemImage(name: icon, size: 20, color: .white)
        .padding(.trailing, 6)
    }
    else { EmptyView() }
  }

  @ViewBuilder
  var Message: some View {
    if let message = message {
      Text(message)
        .font(.system(size: 14))
        .padding(.trailing, action != nil ? 12 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    else { EmptyView() }
  }
  
  @ViewBuilder
  var ActionButton: some View {
    if let action = action {
      Button(actionLabel!) {
        action()
      }
      .controlSize(.small)
      .allowsHitTesting(false)
    }
  }
  
  func show() {
    // show alert
    withAnimation(.spring(dampingFraction: 0.66)) {
      opacity = 1
      offsetY = 0
    }

    // animate countdown
    countdownScale = 1
    withAnimation(.linear(duration: duration.magnitude)) {
      countdownScale = 0
    }
    
    // hide
    Timer.after(duration.magnitude) { _ in hide() }
  }
  
  func hide() {
    withAnimation {
      opacity = 0
      offsetY = 108
    }
    Timer.after(0.5) { _ in alertCtrl.hide() }
  }
  
}

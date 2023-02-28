import SwiftUI


private let cAlertHeight = 54.0
private let cCornerRadius = 18.0
private let cHiddenOffsetY = 108.0


struct AppAlertView: View {
  @EnvironmentObject var viewModel: AppAlertViewModel
  @State var countdownScale = 0.0
  @State var offsetY = cHiddenOffsetY
  @State var opacity = 0.0
  
  var icon: String? { viewModel.icon }
  var message: String? { viewModel.message }
  var visible: Bool { viewModel.visible }
  var duration: TimeInterval { viewModel.duration }
  var delay: TimeInterval { viewModel.delay }
  var action: (() -> Void)? { viewModel.action }
  var actionLabel: String? { viewModel.actionLabel }

  
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
    Timer.after(0.5) { _ in viewModel.hide() }
  }
  
}


class AppAlertViewModel: ObservableObject, Equatable {
  static func == (lhs: AppAlertViewModel, rhs: AppAlertViewModel) -> Bool {
    lhs.message == rhs.message && lhs.icon == rhs.icon
  }
  
  
  @Published var message: String?
  @Published var icon: String?
  @Published var visible: Bool = false
  @Published var action: (() -> Void)?
  @Published var actionLabel: String?
  @Published var duration: TimeInterval = 0
  @Published var delay: TimeInterval = 0
  
  
  func show(
    message: String,
    icon: String,
    duration: TimeInterval = 4,
    delay: TimeInterval = 0,
    action: (() -> Void)? = nil,
    actionLabel: String? = nil
  ) {
    self.message = message
    self.icon = icon
    self.action = action
    self.actionLabel = actionLabel
    self.duration = duration
    self.delay = delay
    self.visible = true
  }
  
  func hide() {
    visible = false
    message = nil
    icon = nil
    action = nil
    actionLabel = nil
    duration = 0
  }
  
}

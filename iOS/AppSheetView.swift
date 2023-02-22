import SwiftUI


enum AppSheetMode {
  case inboxTools
  case emailTools
}


struct AppSheetView: View {
  @Binding var mode: AppSheetMode
  
  var body: some View {
    ZStack {
      OverlayBackgroundView()
      Sheet
        .interactiveDismissDisabled()
        .presentationDetents(
          undimmed: [
            .height(appSheetDetents.min),
            .height(appSheetDetents.mid),
            .height(appSheetDetents.max)
          ]
        )
    }
    .ignoresSafeArea()
    .introspectViewController { vc in
      vc.view.backgroundColor = .clear
    }
  }
  
  @ViewBuilder
  private var Sheet: some View {
    switch mode {
      case .inboxTools: InboxSheetView()
      case .emailTools: EmailToolsSheetView()
    }
  }
  
}

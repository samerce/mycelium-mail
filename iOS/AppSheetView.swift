import SwiftUI


enum AppSheetMode {
  case inboxTools
  case emailTools
}


struct AppSheetView: View {
  
  @Binding var mode: AppSheetMode
  @Binding var bundle: String
  
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
      case .inboxTools: InboxSheetView(bundle: $bundle)
      case .emailTools: EmailToolsSheetView()
    }
  }
  
}

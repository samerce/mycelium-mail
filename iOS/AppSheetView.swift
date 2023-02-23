import SwiftUI
import SwiftUIKit


struct AppSheetDetents {
  var min: CGFloat = 0
  var mid: CGFloat = 0
  var max: CGFloat = 0
}


struct AppSheetView: View {
  @EnvironmentObject var viewModel: ViewModel
  @State var selectedDetent: PresentationDetent = .height(1)
  
  private var mode: AppSheetMode { viewModel.appSheetMode }
  private var detents: [UndimmedPresentationDetent] { mode.detents }
  
  // MARK: - VIEW
  
  var body: some View {
    ZStack {
      OverlayBackgroundView()
      Sheet
        .interactiveDismissDisabled()
        .presentationDetents(undimmed: detents, selection: $selectedDetent)
    }
    .onAppear {
      selectedDetent = mode.initialDetent
    }
    .onReceive(viewModel.$appSheetMode) { mode in
      selectedDetent = mode.initialDetent
    }
    .ignoresSafeArea()
    .introspectViewController { vc in
      vc.view.backgroundColor = .clear
    }
  }
  
  @ViewBuilder
  private var Sheet: some View {
    switch mode {
      case .firstStart, .downloadingEmails: FirstStartView()
      case .inboxTools: InboxSheetView()
      case .emailTools: EmailToolsSheetView()
      default: Text("ERROR: sheet mode not set correctly: \(mode.id)")
    }
  }
  
}

// MARK: - APP SHEET MODE

struct AppSheetMode {
  static let firstStart = Self(
    id: 0,
    detents: [.large],
    initialDetent: .large
  )
  static let downloadingEmails = Self(
    id: 1,
    detents: [.large],
    initialDetent: .large
  )
  static let inboxTools = Self(
    id: 2,
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  static let emailTools = Self(
    id: 3,
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  
  var id: Int
  var detents: [UndimmedPresentationDetent]
  var initialDetent: PresentationDetent
}

extension AppSheetMode: Equatable {
  static func == (lhs: AppSheetMode, rhs: AppSheetMode) -> Bool {
    lhs.id == rhs.id
  }
}

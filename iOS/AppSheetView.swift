import SwiftUI
import SwiftUIKit
import Combine


struct AppSheetDetents {
  static let min: CGFloat = 90
  static let mid: CGFloat = 420
  static let max: CGFloat = 750
  
  var min: CGFloat = 0
  var mid: CGFloat = 0
  var max: CGFloat = 0
}

class AppSheetViewModel: ObservableObject {
  @Published var sheetSize: CGSize = CGSize() {
    didSet {
      let sheetDistanceFromMin = sheetSize.height - AppSheetDetents.min
      let distanceFromMinToMid = AppSheetDetents.mid - AppSheetDetents.min
      percentToMid = min(1, max(0, sheetDistanceFromMin / distanceFromMinToMid))
    }
  }
  
  @Published var percentToMid: CGFloat = 0
}


struct AppSheetView: View {
  @EnvironmentObject var viewModel: ViewModel
  @StateObject var appSheetViewModel = AppSheetViewModel()
  @State var selectedDetent: PresentationDetent = .height(1)
  
  var config: AppSheet { viewModel.appSheet }
  
  // MARK: - VIEW
  
  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .top) {
        OverlayBackgroundView()
        Sheet
          .interactiveDismissDisabled()
          .presentationDetents(undimmed: config.detents, selection: $selectedDetent)
          .presentationDragIndicator(.hidden)
      }
      .height(screenHeight)
      .ignoresSafeArea()
      .environmentObject(appSheetViewModel)
      .introspectViewController { $0.view.backgroundColor = .clear }
      .animation(.spring(dampingFraction: 0.54), value: selectedDetent)
      .onChange(of: geo.size) { _ in
        appSheetViewModel.sheetSize = geo.size
      }
      .onReceive(viewModel.$appSheet) { _config in
        selectedDetent = _config.initialDetent
      }
      .onChange(of: viewModel.selectedBundle) { _ in
        selectedDetent = config.initialDetent
      }
    }
  }
  
  @ViewBuilder
  private var Sheet: some View {
    switch config {
      case .firstStart, .downloadingEmails: FirstStartView()
      case .inboxTools: InboxSheetView()
      case .emailTools: EmailToolsSheetView()
      case .createBundle: CreateBundleView()
      default: Text("ERROR: missing view for sheet mode '\(config.id)'")
    }
  }
  
}

// MARK: - APP SHEET MODE

struct AppSheet {
  static let firstStart = Self(
    id: "first start",
    detents: [.large],
    initialDetent: .large
  )
  static let downloadingEmails = Self(
    id: "downloading emails",
    detents: [.large],
    initialDetent: .large
  )
  static let inboxTools = Self(
    id: "inbox tools",
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  static let emailTools = Self(
    id: "email tools",
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  static let createBundle = Self(
    id: "create bundle",
    detents: [.height(272)],
    initialDetent: .height(272)
  )
  static let bundleSettings = Self(
    id: "bundle settings",
    detents: [.large],
    initialDetent: .large
  )
  
  var id: String
  var detents: [UndimmedPresentationDetent]
  var initialDetent: PresentationDetent
}

extension AppSheet: Equatable {
  static func == (lhs: AppSheet, rhs: AppSheet) -> Bool {
    lhs.id == rhs.id
  }
}

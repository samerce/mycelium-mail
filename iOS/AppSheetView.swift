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
  
  private var mode: AppSheetMode { viewModel.appSheetMode }
  private var detents: [UndimmedPresentationDetent] { mode.detents }
  
  // MARK: - VIEW
  
  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .top) {
        OverlayBackgroundView()
        Sheet
          .interactiveDismissDisabled()
          .presentationDetents(undimmed: detents, selection: $selectedDetent)
          .presentationDragIndicator(.hidden)
      }
      .ignoresSafeArea()
      .environmentObject(appSheetViewModel)
      .introspectViewController { $0.view.backgroundColor = .clear }
      .onAppear {
        selectedDetent = mode.initialDetent
      }
      .onReceive(viewModel.$appSheetMode) { mode in
        withAnimation {
          selectedDetent = mode.initialDetent
        }
      }
      .onChange(of: geo.size) { _ in
        appSheetViewModel.sheetSize = geo.size
      }
      .onChange(of: viewModel.selectedBundle) { _ in
        selectedDetent = mode.initialDetent
      }
    }
  }
  
  @ViewBuilder
  private var Sheet: some View {
    switch mode {
      case .firstStart, .downloadingEmails: FirstStartView()
      case .inboxTools: InboxSheetView()
      case .emailTools: EmailToolsSheetView()
      case .createBundle: CreateBundleView()
      default: Text("ERROR: missing view for sheet mode '\(mode.name)'")
    }
  }
  
}

// MARK: - APP SHEET MODE

struct AppSheetMode {
  static let firstStart = Self(
    name: "first start",
    detents: [.large],
    initialDetent: .large
  )
  static let downloadingEmails = Self(
    name: "downloading emails",
    detents: [.large],
    initialDetent: .large
  )
  static let inboxTools = Self(
    name: "inbox tools",
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  static let emailTools = Self(
    name: "email tools",
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  static let createBundle = Self(
    name: "create bundle",
    detents: [.height(272)],
    initialDetent: .height(272)
  )
  
  var name: String
  var detents: [UndimmedPresentationDetent]
  var initialDetent: PresentationDetent
}

extension AppSheetMode: Equatable {
  static func == (lhs: AppSheetMode, rhs: AppSheetMode) -> Bool {
    lhs.name == rhs.name
  }
}

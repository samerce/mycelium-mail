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


struct AppSheetView: View {
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @State var selectedDetent: PresentationDetent = .height(1)
  @State var config: AppSheet = .inbox
  @State var detents: [UndimmedPresentationDetent] = [.height(AppSheetDetents.min)]
  
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
      .introspectViewController { $0.view.backgroundColor = .clear }
      .animation(.spring(dampingFraction: 0.54), value: selectedDetent)
      .onChange(of: geo.size) { _ in
        sheetCtrl.sheetSize = geo.size
      }
      .onChange(of: bundleCtrl.selectedBundle) { _ in
        selectedDetent = config.initialDetent
      }
      .onReceive(sheetCtrl.$sheet) { newConfig in
        detents = newConfig.detents + config.detents
        selectedDetent = newConfig.initialDetent
        
        Timer.after(0.1) { _ in
          detents = newConfig.detents
          withAnimation { config = newConfig }
        }
      }
    }
  }
  
  @ViewBuilder
  private var Sheet: some View {
    switch config {
      case .firstStart, .downloadingEmails: FirstStartView()
      case .inbox: InboxSheetView()
      case .emailDetail: EmailDetailSheetView()
      case .createBundle: CreateBundleView()
      case .bundleSettings: BundleSettingsView()
      default: Text("ERROR: missing view for sheet mode '\(config.id)'")
    }
  }
  
}

// MARK: - APP SHEET CONFIG

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
  static let inbox = Self(
    id: "inbox tools",
    detents: [
      .height(90), // TODO: fix magic number
      .medium,
      .large
    ],
    initialDetent: .height(90)
  )
  static let emailDetail = Self(
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
    detents: [.medium, .large],
    initialDetent: .medium
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

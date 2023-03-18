import SwiftUI
import SwiftUIKit
import Combine


let initialSheet = AppSheet.inbox


struct AppSheetView: View {
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @State var selectedDetent: PresentationDetent = initialSheet.initialDetent
  @State var config: AppSheet = initialSheet
  @State var detents: [UndimmedPresentationDetent] = [.height(AppSheetDetents.min)]
  
  // MARK: - VIEW
  
  var body: some View {
    ZStack(alignment: .top) {
      OverlayBackgroundView()
      Sheet
        .interactiveDismissDisabled()
        .presentationDetents(undimmed: detents, selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
    }
    .ignoresSafeArea()
    .geo($sheetCtrl.sheetSize)
    .introspectViewController { $0.view.backgroundColor = .clear }
    .animation(.spring(dampingFraction: 0.54), value: selectedDetent)
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
  
  @ViewBuilder
  private var Sheet: some View {
    switch config {
      case .firstStart, .downloadingEmails: FirstStartView()
      case .inbox: InboxSheetView()
      case .emailThread: EmailThreadSheetView()
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
      .height(AppSheetDetents.min),
      .medium,
      .large
    ],
    initialDetent: .height(AppSheetDetents.min)
  )
  static let emailThread = Self(
    id: "email tools",
    detents: [
      .height(AppSheetDetents.min),
      .medium,
      .large
    ],
    initialDetent: .height(AppSheetDetents.min)
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


struct AppSheetDetents {
  static let min: CGFloat = 90
  static let mid: CGFloat = 420
  static let max: CGFloat = 750
  
  var min: CGFloat = 0
  var mid: CGFloat = 0
  var max: CGFloat = 0
}

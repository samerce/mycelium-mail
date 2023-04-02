import SwiftUI
import SwiftUIKit


struct AppSheetView: View {
  @ObservedObject var bundleCtrl = BundleController.shared
  @ObservedObject var sheetCtrl = SheetController.shared
  
  @State var sheet: AppSheet
  @State var detents: [UndimmedPresentationDetent]
  @State var selectedDetent: PresentationDetent
  
  init(sheet: AppSheet) {
    _sheet = State(initialValue: sheet)
    _detents = State(initialValue: sheet.detents)
    _selectedDetent = State(initialValue: sheet.initialDetent)
  }
  
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
      selectedDetent = sheet.initialDetent
    }
    .onReceive(sheetCtrl.$sheet) { newSheet in
      detents = newSheet.detents + sheet.detents
      selectedDetent = newSheet.initialDetent
      
      Timer.after(0.1) { _ in
        detents = newSheet.detents
        withAnimation { sheet = newSheet }
      }
    }
    .onReceive(sheetCtrl.$selectedDetent) { _ in
      selectedDetent = sheetCtrl.selectedDetent
    }
  }
  
  @ViewBuilder
  private var Sheet: some View {
    switch sheet {
      case .firstStart, .downloadingEmails: FirstStartView()
      case .inbox: InboxSheetView()
      case .emailThread: EmailThreadSheetView()
      case .createBundle: CreateBundleView()
      case .bundleSettings: BundleSettingsView()
      default: Text("ERROR: missing view for sheet mode '\(sheet.id)'")
    }
  }
  
}

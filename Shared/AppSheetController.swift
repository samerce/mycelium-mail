import Foundation
import Combine


private let mailCtrl = MailController.shared


class AppSheetController: ObservableObject {
  static let shared = AppSheetController()
  
  @Published var sheet: AppSheet = .firstStart
  @Published var percentToMid: CGFloat = 0
  var sheetSize: CGSize = CGSize() {
    didSet {
      let sheetDistanceFromMin = sheetSize.height - AppSheetDetents.min
      let distanceFromMinToMid = AppSheetDetents.mid - AppSheetDetents.min
      percentToMid = min(1, max(0, sheetDistanceFromMin / distanceFromMinToMid))
    }
  }
  var args: [Any] = []
  
  private var initSubscribers: [AnyCancellable] = []
  
  // MARK: -
  
  private init() {
    // set the sheet mode based on email availability
    mailCtrl.$emailsInSelectedBundle
      .sink { emails in
        if !emails.isEmpty && self.sheet == .firstStart {
          self.sheet = .inbox
          self.initSubscribers.forEach { $0.cancel() }
        }
      }
      .store(in: &initSubscribers)
  }
  
  deinit {
    initSubscribers.forEach { $0.cancel() }
  }
  
  // MARK: - PUBLIC
  
  func showSheet(_ sheet: AppSheet, _ args: Any...) {
    self.sheet = sheet
    self.args = args
  }
  
}

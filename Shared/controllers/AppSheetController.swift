import Foundation
import SwiftUI
import Combine
import SwiftUIKit


private let mailCtrl = MailController.shared
private let initialSheet = AppSheet.inbox


class AppSheetController: ObservableObject {
  static let shared = AppSheetController()
  
  @Published var sheet: AppSheet = initialSheet
  @Published var selectedDetent: PresentationDetent = initialSheet.initialDetent
  @Published var percentToMid: CGFloat = 0
  @AppStorage(AppStorageKeys.completedInitialDownload) var completedInitialDownload = false
  
  var sheetSize: CGSize = CGSize() {
    didSet {
      let sheetDistanceFromMin = sheetSize.height - AppSheetDetents.min
      let distanceFromMinToMid = AppSheetDetents.mid - AppSheetDetents.min
      percentToMid = min(1, max(0, sheetDistanceFromMin / distanceFromMinToMid))
    }
  }
  var args: [Any] = []
  
  // MARK: -
  
  private init() {
    sheet = completedInitialDownload ? .inbox : .firstStart
  }
  
  // MARK: - PUBLIC
  
  func showSheet(_ sheet: AppSheet, _ args: Any...) {
    self.sheet = sheet
    self.args = args
  }
  
  func setDetent(_ detent: PresentationDetent) {
    selectedDetent = detent
  }
  
}

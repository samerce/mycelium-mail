import Foundation
import CoreData
import Combine


class EmailBundleController: NSObject, ObservableObject {
  static let shared = EmailBundleController()
  
  @Published var emailToMoveToNewBundle: Email? // TODO: find a better place for this
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle {
    didSet {
      markSelectedBundleSeenWithDelay()
    }
  }
  
  let bundleCtrl: NSFetchedResultsController<EmailBundle>
  let accountCtrl = AccountController.shared
  let dataCtrl = PersistenceController.shared
  
  var markSeenTimer: Timer?

  // MARK: -
  
  private override init() {
    let bundleRequest = EmailBundle.fetchRequestWithProps("name", "labelId")
    bundleCtrl = NSFetchedResultsController(fetchRequest: bundleRequest,
                                            managedObjectContext: dataCtrl.context,
                                            sectionNameKeyPath: nil,
                                            cacheName: nil) // TODO: cache?
    try? bundleCtrl.performFetch()
    
    let bundles = bundleCtrl.fetchedObjects ?? []
    var inboxBundle = bundles.first(where: { $0.name == "inbox" })
    
    if inboxBundle == nil {
      inboxBundle = EmailBundle(
        name: "inbox",
        labelId: "",
        icon: "tray.full",
        orderIndex: 2, //bundles.count, TODO: uncomment this for release
        context: dataCtrl.context
      )
    }
    selectedBundle = inboxBundle!
    
    super.init()
    bundleCtrl.delegate = self
    
    update()
    markSelectedBundleSeenWithDelay()
  }
  
  private func update() {
    DispatchQueue.main.async {
      print("updating bundles")
      self.bundles = self.bundleCtrl.fetchedObjects ?? []
    }
  }
  
  private func markSelectedBundleSeenWithDelay() {
    markSeenTimer?.invalidate()
    markSeenTimer = Timer.after(1) { _ in
      self.dataCtrl.context.perform {
        self.selectedBundle.onSelected()
        self.dataCtrl.save()
      }
    }
  }
  
}

extension EmailBundleController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}

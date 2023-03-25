import Foundation
import CoreData
import Combine


class EmailBundleController: NSObject, ObservableObject {
  static let shared = EmailBundleController()
  
  @Published var threadToMoveToNewBundle: EmailThread? // TODO: find a better place for this
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
      dataCtrl.save()
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

// MARK: - PUBLIC

extension EmailBundleController {
  
  func initDefaultBundles() {
//    makePreconfiguredBundleNamed("sent")
//    makePreconfiguredBundleNamed("drafts")
//    dataCtrl.save()
  }
  
  private func makePreconfiguredBundleNamed(_ name: String) {
    let configIndex = cBundleConfig.firstIndex(where: { $0["name"] == name })!
    let config = cBundleConfig[configIndex]
    let _ = EmailBundle(
      name: name,
      labelId: "",
      icon: config["icon"],
      orderIndex: configIndex,
      context: dataCtrl.context
    )
  }
  
}

// MARK: - FETECHED RESULTS CONTROLLER DELEGATE

extension EmailBundleController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}

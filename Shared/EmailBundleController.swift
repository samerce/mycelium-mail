import Foundation
import CoreData


private let moc = PersistenceController.shared.container.viewContext


class EmailBundleController: NSObject, ObservableObject {
  static let shared = EmailBundleController()
  
  let bundleCtrl: NSFetchedResultsController<EmailBundle>
  
  @Published var emailToMoveToNewBundle: Email? // TODO: find a better place for this
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle
  
  private override init() {
    let bundleRequest = EmailBundle.fetchRequestWithProps("name", "gmailLabelId")
    bundleRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
    bundleCtrl = NSFetchedResultsController(fetchRequest: bundleRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil) // TODO: cache?
    try? bundleCtrl.performFetch()
    
    let bundles = bundleCtrl.fetchedObjects ?? []
    var inboxBundle = bundles.first(where: { $0.name == "inbox" })
    
    if inboxBundle == nil {
      inboxBundle = EmailBundle(
        name: "inbox",
        gmailLabelId: "",
        icon: "tray.full",
        orderIndex: bundles.count,
        context: moc
      )
    }
    selectedBundle = inboxBundle!
    
    super.init()
    bundleCtrl.delegate = self
    self.update()
  }
  
  private func update() {
    DispatchQueue.main.async {
      print("updating bundles")
      self.bundles = self.bundleCtrl.fetchedObjects ?? []
    }
  }
  
}

extension EmailBundleController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}

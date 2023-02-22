import Foundation
import Combine
import CoreData


private let moc = PersistenceController.shared.container.viewContext


class ViewModel: NSObject, ObservableObject {
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle? {
    didSet {
      emailCtrl.fetchRequest.predicate = Email.predicateForBundle(selectedBundle)
      try? emailCtrl.performFetch()
      emailsInSelectedBundle = emailCtrl.fetchedObjects ?? []
    }
  }
  @Published var emailsInSelectedBundle: [Email]?
  
  private let bundleCtrl: NSFetchedResultsController<EmailBundle>
  private let emailCtrl: NSFetchedResultsController<Email>
  
  override init() {
    let bundleRequest = EmailBundle.fetchRequest()
    bundleCtrl = NSFetchedResultsController(fetchRequest: bundleRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil)
    try? bundleCtrl.performFetch()
    let selectedBundle = bundleCtrl.fetchedObjects?.first(where: { $0.name == "inbox" })
    
    let emailRequest = Email.fetchRequestForBundle(selectedBundle)
    emailCtrl = NSFetchedResultsController(fetchRequest: emailRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil)
    try? emailCtrl.performFetch()
    
    super.init()
    bundleCtrl.delegate = self
    emailCtrl.delegate = self
    
    DispatchQueue.main.async {
      self.bundles = self.bundleCtrl.fetchedObjects ?? []
      self.selectedBundle = selectedBundle
      self.emailsInSelectedBundle = self.emailCtrl.fetchedObjects ?? []
    }
  }
}

extension ViewModel: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    if controller == bundleCtrl {
      bundles = bundleCtrl.fetchedObjects ?? []
    }
    else if controller == emailCtrl {
      emailsInSelectedBundle = emailCtrl.fetchedObjects ?? []
    }
  }
  
}

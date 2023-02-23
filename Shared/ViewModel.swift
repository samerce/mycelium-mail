import Foundation
import Combine
import CoreData


private let moc = PersistenceController.shared.container.viewContext


class ViewModel: NSObject, ObservableObject {
  private let mailCtrl = MailController.shared
  
  @Published var appSheetMode: AppSheetMode = .firstStart
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle {
    didSet {
      emailCtrl.fetchRequest.predicate = Email.predicateForBundle(selectedBundle)
      try? emailCtrl.performFetch()
      emailsInSelectedBundle = emailCtrl.fetchedObjects ?? []
    }
  }
  @Published var emailsInSelectedBundle: [Email] = []
  
  private let bundleCtrl: NSFetchedResultsController<EmailBundle>
  private let emailCtrl: NSFetchedResultsController<Email>
  
  override init() {
    let bundleRequest = EmailBundle.fetchRequest()
    bundleCtrl = NSFetchedResultsController(fetchRequest: bundleRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil)
    try? bundleCtrl.performFetch()
    
    let _selectedBundle = (bundleCtrl.fetchedObjects?.first(where: { $0.name == "inbox" }))!
    selectedBundle = _selectedBundle
    
    let emailRequest = Email.fetchRequestForBundle(_selectedBundle)
    emailCtrl = NSFetchedResultsController(fetchRequest: emailRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil)
    try? emailCtrl.performFetch()
    
    if let emails = emailCtrl.fetchedObjects,
       !emails.isEmpty {
      appSheetMode = .inboxTools
    }
    
    super.init()
    bundleCtrl.delegate = self
    emailCtrl.delegate = self
    self.update()
  }
  
  private func update() {
    DispatchQueue.main.async {
      print("updating fetched results")
      
      self.bundles = self.bundleCtrl.fetchedObjects ?? []
      self.emailsInSelectedBundle = self.emailCtrl.fetchedObjects ?? []
    }
  }
}

extension ViewModel: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}

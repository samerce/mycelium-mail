import Foundation
import Combine
import CoreData
import UIKit


private let moc = PersistenceController.shared.container.viewContext


class ViewModel: NSObject, ObservableObject {
  private let mailCtrl = MailController.shared

  @Published var appSheetMode: AppSheetMode = .firstStart
  @Published var emailToMoveToNewBundle: Email?
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle {
    didSet {
      emailCtrl.fetchRequest.predicate = Email.predicateForBundle(selectedBundle)
      try? emailCtrl.performFetch()
      emailsInSelectedBundle = emailCtrl.fetchedObjects ?? []
    }
  }
  @Published var emailsInSelectedBundle: [Email] = []
  var navController: UINavigationController?
  
  private let bundleCtrl: NSFetchedResultsController<EmailBundle>
  private let emailCtrl: NSFetchedResultsController<Email>
  
  
  override init() {
    // fetch bundles
    let bundleRequest = EmailBundle.fetchRequest()
    bundleRequest.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
    bundleCtrl = NSFetchedResultsController(fetchRequest: bundleRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil) // TODO: cache?
    try? bundleCtrl.performFetch()
    
    // select the inbox bundle
    let _selectedBundle = (bundleCtrl.fetchedObjects?.first(where: { $0.name == "inbox" }))!
    selectedBundle = _selectedBundle
    
    // fetch emails in inbox bundle
    let emailRequest = Email.fetchRequestForBundle(_selectedBundle)
    emailCtrl = NSFetchedResultsController(fetchRequest: emailRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil) // TODO: cache?
    try? emailCtrl.performFetch()
    
    // set the sheet mode based on email availability
    if let emails = emailCtrl.fetchedObjects,
       !emails.isEmpty {
      appSheetMode = .inboxTools
    }
    
    // finish init
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

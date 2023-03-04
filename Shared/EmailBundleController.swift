import Foundation
import CoreData
import Combine


private let moc = PersistenceController.shared.container.viewContext


class EmailBundleController: NSObject, ObservableObject {
  static let shared = EmailBundleController()
  
  @Published var emailToMoveToNewBundle: Email? // TODO: find a better place for this
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle
  
  let bundleCtrl: NSFetchedResultsController<EmailBundle>
  let accountCtrl = AccountController.shared
  private var subscribers: [AnyCancellable] = []
  
  
  private override init() {
    let bundleRequest = EmailBundle.fetchRequestWithProps("name", "gmailLabelId")
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
        orderIndex: 2, //bundles.count, TODO: uncomment this for release
        context: moc
      )
    }
    selectedBundle = inboxBundle!
    
    super.init()
    bundleCtrl.delegate = self
    
    subscribeToSignedInAccounts()
    update()
  }
  
  deinit {
    subscribers.forEach { $0.cancel() }
  }
  
  private func update() {
    DispatchQueue.main.async {
      print("updating bundles")
      self.bundles = self.bundleCtrl.fetchedObjects ?? []
    }
  }
  
  private func subscribeToSignedInAccounts() {
    accountCtrl.$signedInAccounts
      .sink { accounts in
        accounts.forEach { account in
          Task {
            try? await self.syncEmailBundles(account) // TODO: handle error
          }
        }
      }
      .store(in: &subscribers)
  }
  
  /// gotta sync bundles before fetch, cuz on first start the bundles must exist while emails are being created
  private func syncEmailBundles(_ account: Account) async throws {
    let bundleFetchRequest = EmailBundle.fetchRequestWithProps("name", "gmailLabelId")
    let bundles = try? moc.fetch(bundleFetchRequest)
    
    let (labelListResponse, _) = try await GmailEndpoint.call(.listLabels, forAccount: account)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    // TODO: use batch insert?
    labels.enumerated().forEach { index, label in
      if !label.name.contains("psymail/") {
        return
      }
      
      let bundleName = label.name.replacing("psymail/", with: "")
      var bundle = bundles?.first(where: { $0.name == bundleName })
      if bundle == nil {
        let config = cBundleConfigByName[bundleName]
        bundle = EmailBundle(
          name: bundleName,
          gmailLabelId: label.id,
          icon: config?["icon"] ?? "questionmark.square",
          orderIndex: cBundleConfig.firstIndex(where: { $0["name"] == bundleName }) ?? bundles?.count ?? index,
          context: moc
        )
      } else {
        // TODO: update this to work with multiple accounts
        bundle!.gmailLabelId = label.id
      }
    }
    
    PersistenceController.shared.save()
  }
  
}

extension EmailBundleController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}


// TODO: get rid of this
private let cBundleConfig = [
  [
    "name": "notifications",
    "icon": "bell"
  ],
  [
    "name": "commerce",
    "icon": "creditcard"
  ],
  [
    "name": "inbox",
    "icon": "tray.full"
  ],
  [
    "name": "newsletters",
    "icon": "newspaper"
  ],
  [
    "name": "society",
    "icon": "building.2"
  ],
  [
    "name": "marketing",
    "icon": "megaphone"
  ],
  [
    "name": "updates",
    "icon": "livephoto"
  ],
  [
    "name": "events",
    "icon": "calendar"
  ],
  [
    "name": "jobs",
    "icon": "briefcase",
  ],
  [
    "name": "health",
    "icon": "heart.text.square"
  ],
  [
    "name": "travel",
    "icon": "backpack"
  ]
]
private let cBundleConfigByName = cBundleConfig.reduce(into: [:], { result, config in
  result[config["name"]] = config
})

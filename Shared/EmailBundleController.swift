import Foundation
import CoreData
import Combine


class EmailBundleController: NSObject, ObservableObject {
  static let shared = EmailBundleController()
  
  @Published var emailToMoveToNewBundle: Email? // TODO: find a better place for this
  @Published var bundles = [EmailBundle]()
  @Published var selectedBundle: EmailBundle {
    didSet {
      markSelectedBundleSeen()
    }
  }
  @Published var syncedAccounts = Set<Account>()
  
  let bundleCtrl: NSFetchedResultsController<EmailBundle>
  let accountCtrl = AccountController.shared
  let dataCtrl = PersistenceController.shared
  private var subscribers: [AnyCancellable] = []
  
  
  private override init() {
    let bundleRequest = EmailBundle.fetchRequestWithProps("name", "gmailLabelId")
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
        gmailLabelId: "",
        icon: "tray.full",
        orderIndex: 2, //bundles.count, TODO: uncomment this for release
        context: dataCtrl.context
      )
    }
    selectedBundle = inboxBundle!
    
    super.init()
    bundleCtrl.delegate = self
    
    subscribeToSignedInAccounts()
    update()
    markSelectedBundleSeen()
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
            do {
              try await self.syncEmailBundles(account) // TODO: handle error
              DispatchQueue.main.async {
                self.syncedAccounts.insert(account)
              }
              print("\(account.address): bundle sync complete!")
            }
            catch {
              print("\(account.address): error syncing email bundles\n\(error.localizedDescription)")
            }
          }
        }
      }
      .store(in: &subscribers)
  }
  
  /// gotta sync bundles before fetch, cuz on first start the bundles must exist while emails are being created
  private func syncEmailBundles(_ account: Account) async throws {
    let context = dataCtrl.context
    
    let bundleFetchRequest = EmailBundle.fetchRequestWithProps("name", "gmailLabelId")
    let bundles = try context.fetch(bundleFetchRequest)
    
    let (labelListResponse, _) = try await GmailEndpoint.call(.listLabels, forAccount: account)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    // TODO: use batch insert?
    for label in labels {
      if !label.name.contains("psymail/") {
        continue
      }
      
      let bundleName = label.name.replacing("psymail/", with: "")
      let bundle = bundles.first(where: { $0.name == bundleName })
        ?? makeBundleNamed(bundleName, labelId: label.id, fallbackIndex: bundles.count)
      
      // TODO: update this to work with multiple accounts
      bundle.gmailLabelId = label.id
    }
    
    dataCtrl.save()
  }
  
  private func markSelectedBundleSeen() {
    Timer.after(2) { _ in
      self.dataCtrl.context.perform {
        self.selectedBundle.onSelected()
        self.dataCtrl.save()
      }
    }
  }
  
  private func makeBundleNamed(_ name: String, labelId: String, fallbackIndex: Int) -> EmailBundle {
    let config = cBundleConfigByName[name]
    let orderIndex = cBundleConfig.firstIndex(where: { $0["name"] == name }) // TODO: fix for prod
    
    return EmailBundle(
      name: name,
      gmailLabelId: labelId,
      icon: config?["icon"] ?? "questionmark.square",
      orderIndex: orderIndex ?? fallbackIndex,
      context: dataCtrl.context
    )
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
    "name": "updates",
    "icon": "livephoto"
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
    "name": "events",
    "icon": "calendar"
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
    "name": "commerce",
    "icon": "creditcard"
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

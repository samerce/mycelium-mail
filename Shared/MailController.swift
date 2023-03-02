import Foundation
import MailCore
import Combine
import SwiftUI
import CoreData
import SymbolPicker


let DefaultFolder = "[Gmail]/All Mail" //"INBOX"
let cInboxLabel = "\\Inbox"

private let moc = PersistenceController.shared.container.viewContext
private let bundleCtrl = EmailBundleController.shared
private let accountCtrl = AccountController.shared


class MailController: NSObject, ObservableObject {
  static let shared = MailController()
  
  @Published var model: MailModel = MailModel()
  @Published private(set) var fetching = false
  @Published var emailsInSelectedBundle: [Email] = []
  var navController: UINavigationController? // TODO: find a better place for this

  private var subscribers: [AnyCancellable] = []
  private let emailCtrl: NSFetchedResultsController<Email>
  private var sessions: [Account: MCOIMAPSession] {
    AccountController.shared.sessions
  }
  
  // MARK: -
  
  private override init() {
    let emailRequest = Email.fetchRequestForBundle(bundleCtrl.selectedBundle)
    emailCtrl = NSFetchedResultsController(fetchRequest: emailRequest,
                                           managedObjectContext: moc,
                                           sectionNameKeyPath: nil,
                                           cacheName: nil) // TODO: cache?
    try? emailCtrl.performFetch()
    
    super.init()
    emailCtrl.delegate = self
    
    // update emails when selected bundle changes
    bundleCtrl.$selectedBundle
      .sink { selectedBundle in
        self.emailCtrl.fetchRequest.predicate = Email.predicateForBundle(selectedBundle)
        try? self.emailCtrl.performFetch()
        self.update()
      }
      .store(in: &subscribers)
    
    subscribeToSignedInAccounts()
    update()
  }
  
  deinit {
    subscribers.forEach { $0.cancel() }
  }
  
  private func update() {
    DispatchQueue.main.async {
      print("updating email results")
      self.emailsInSelectedBundle = self.emailCtrl.fetchedObjects ?? []
    }
  }
  
  private func subscribeToSignedInAccounts() {
    accountCtrl.$signedInAccounts
      .sink { accounts in
        accounts.forEach(self.onSignedInAccount)
      }
      .store(in: &subscribers)
  }
  
  func onSignedInAccount(_ account: Account) {
    print("\(account.address) signed in")
    
    Task {
      try? await self.fetchLatest(account) // TODO: handle error
    }
  }
  
  // MARK: - API
  
  func fetchLatest() async throws {
    for account in accountCtrl.signedInAccounts {
      try await self.fetchLatest(account)
    }
  }
  
  func moveEmail(_ email: Email, fromBundle: EmailBundle, toBundle: EmailBundle, always: Bool = true) async throws {
    // proactively update core data and revert if update request fails
    email.removeFromBundleSet(fromBundle)
    email.addToBundleSet(toBundle)
    fromBundle.removeFromEmailSet(email)
    toBundle.addToEmailSet(email)
    PersistenceController.shared.save()
    
    if toBundle.name == "inbox" {
      try await email.removeLabels(["psymail/\(fromBundle.name)"])
      // TODO: delete filter
      return
    }
    
    do {
      try await email.addLabels(["psymail/\(toBundle.name)"])
      try await email.removeLabels([cInboxLabel])
    }
    catch {
      print(error.localizedDescription)
      email.removeFromBundleSet(toBundle)
      email.addToBundleSet(fromBundle)
      fromBundle.addToEmailSet(email)
      toBundle.removeFromEmailSet(email)
      PersistenceController.shared.save()
      // TODO: figure out UX
      throw error
    }
    
    if always {
      do {
        try await createFilterFor(email: email, bundle: toBundle)
      }
      catch {
        print("error creating bundle filter: \(error.localizedDescription)")
        throw error
      }
    }
  }
  
  private func createFilterFor(email: Email, bundle: EmailBundle) async throws {
    guard let address = email.from?.address,
          let account = email.account
    else {
      throw PsyError.unexpectedError(message: "email had no 'from' address to create filter with")
    }
    
    var filterExistsForSameBundle = false
    var filterIdToDelete: String? = nil
    
    let (filterListResponse, _) = try await GmailEndpoint.call(.listFilters, forAccount: account)
    let filters = (filterListResponse as! GFilterListResponse).filter
    
    filters.forEach { filter in
      if let addLabelIds = filter.action?.addLabelIds ?? nil,
         let from = filter.criteria?.from ?? nil,
         from.contains(address) {
       
        if addLabelIds.contains(bundle.gmailLabelId) {
          filterExistsForSameBundle = true
        } else {
          // filter exists for diff bundle so delete it and create the new filter
          filterIdToDelete = filter.id
        }
      }
    }
    
    if filterExistsForSameBundle {
      print("filter already exists to send \(address) to \(bundle.name), skipping create filter step")
      return
    }
    
    if let id = filterIdToDelete {
      print("filter already exists to send \(address) to a different bundle; deleting existing filter")
      try await GmailEndpoint.call(.deleteFilter(id: id), forAccount: account)
    }
    
    print("creating filter for \(address) to \(bundle.name)")
    try await GmailEndpoint.call(.createFilter, forAccount: account, withBody: [
      /// see:  https://developers.google.com/gmail/api/guides/filter_settings
      "criteria": [
        "from": address,
      ],
      "action": [
        "addLabelIds": [bundle.gmailLabelId],
        "removeLabelIds": ["INBOX", "SPAM"] // skip the inbox, never send to spam
      ]
    ])
  }
  
  // MARK: - private
  
  private func fetchLatest(_ account: Account) async throws {
    DispatchQueue.main.async {
      self.fetching = true
    }
    
    let startUid = model.highestEmailUid() + 1
    let endUid = UInt64.max - startUid
    let uids = MCOIndexSet(range: MCORangeMake(startUid, endUid))
    
    print("fetching — startUid: \(startUid), endUid: \(endUid)")
    
    let session = sessions[account]!
    let fetchHeadersAndFlags = session.fetchMessagesOperation(
      withFolder: DefaultFolder,
      requestKind: [.fullHeaders, .flags, .gmailLabels, .gmailThreadID, .gmailMessageID],
      uids: uids
    )
    
    let _: () = try await withCheckedThrowingContinuation { continuation in
      fetchHeadersAndFlags?.start {
        (error: Error?, messages: [MCOIMAPMessage]?, vanishedMessages: MCOIndexSet?) in
        if let error = error {
          continuation.resume(throwing: PsyError.unexpectedError(error))
          return
        }
        
        if messages?.count == 0 {
          DispatchQueue.main.async {
            UserDefaults.standard.set(Date.now.ISO8601Format(), forKey: "lastUpdated")
            self.fetching = false
            print("done fetching!")
          }
        }
        
        if messages != nil {
          self.saveMessages(messages!, account: account)
        }
        continuation.resume()
      }
    }
  }
  
  private func saveMessages(_ messages: [MCOIMAPMessage], account: Account) {
    for message in messages {
      do {
        try model.makeEmail(withMessage: message, account: account)
        print("created \(message.uid), \(message.header.subject ?? "")")
      }
      catch {
        print("error saving new email message to core data: \(error.localizedDescription)")
      }
    }

    model.save()
    print("done saving new messages!")
  }
  
}


extension MailController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}

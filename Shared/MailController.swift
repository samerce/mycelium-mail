import Foundation
import MailCore
import Combine
import SwiftUI
import CoreData
import SymbolPicker


let DefaultFolder = "[Gmail]/All Mail" //"INBOX"
let cInboxLabel = "\\Inbox"
let cSentLabel = "\\Sent"

private let bundleCtrl = EmailBundleController.shared
private let accountCtrl = AccountController.shared
private let dataCtrl = PersistenceController.shared
private let moc = dataCtrl.container.viewContext


class MailController: NSObject, ObservableObject {
  static let shared = MailController()
  
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
    await moc.perform {
      // proactively update core data and revert if update request fails
      email.removeFromBundleSet(fromBundle)
      email.addToBundleSet(toBundle)
      fromBundle.removeFromEmailSet(email)
      toBundle.addToEmailSet(email)
      dataCtrl.save()
    }
    
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
      dataCtrl.save()
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
    let account = email.account
    let address = email.from.address
    
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
  
  func emailsFromSenderOf(_ email: Email) -> [Email] {
    let senderAddress = email.from.address
    if senderAddress.isEmpty { return [] }
    
    var predicate: NSPredicate
    let predicateFormatBase = "from.address == %@ OR sender.address == %@"
    
    let senderDisplayName = email.from.displayName
    if senderDisplayName != nil, senderDisplayName!.isEmpty {
      predicate = NSPredicate(
        format: predicateFormatBase,
        senderAddress,
        senderAddress
      )
    } else {
      predicate = NSPredicate(
        format: predicateFormatBase +
        " OR from.displayName == %@ OR sender.displayName == %@",
        senderAddress,
        senderAddress,
        senderDisplayName!,
        senderDisplayName!
      )
    }
    
    let emailFetchRequest:NSFetchRequest<Email> = Email.fetchRequest()
    emailFetchRequest.predicate = predicate
    
    do {
      return try moc.fetch(emailFetchRequest)
    }
    catch let error {
      print("error fetching emails from sender: \(error.localizedDescription)")
    }
    
    return []
  }
  
  // MARK: - private
  
  private func fetchLatest(_ account: Account) async throws {
    DispatchQueue.main.async {
      self.fetching = true
    }
    
    let startUid = highestEmailUid() + 1
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
        
        Task {
          do {
//            let context = dataCtrl.newTaskContext()
            try await self.onReceivedMessages(messages, forAccount: account, context: moc)
            
            DispatchQueue.main.async {
              if moc.hasChanges {
                try! moc.save()
              }
            }
            
            print("done saving new messages!")
            continuation.resume()
          }
          catch {
            print("error saving fetched messages \(error.localizedDescription)")
            continuation.resume(throwing: error)
          }
        }
      }
    }
  }
  
  private func onReceivedMessages(
    _ messages: [MCOIMAPMessage]?, forAccount account: Account, context: NSManagedObjectContext
  ) async throws {
    
    guard let messages = messages,
          messages.count > 0
    else {
      print("done fetching!")
      
      DispatchQueue.main.async {
        UserDefaults.standard.set(Date.now.ISO8601Format(), forKey: "lastUpdated")
        self.fetching = false
      }
      return
    }
    
    var index = 0
    let emailBatchInsertRequest = NSBatchInsertRequest(entityName: "Email", managedObjectHandler: { managedObject in
      guard index < messages.count
      else { return true }
      
      let message = messages[index]
      let header = message.header!
      let email = managedObject as! Email
      
      email.hydrateWithMessage(message)
      
      print("created \(message.uid), \(header.subject ?? "")")
      index += 1
      return false
    })
    emailBatchInsertRequest.resultType = .objectIDs
    
    var objectIDs = [NSManagedObjectID]()
    try await context.perform {
      let insertResult = try context.execute(emailBatchInsertRequest) as? NSBatchInsertResult
      objectIDs = insertResult?.result as? [NSManagedObjectID] ?? []
      
      guard insertResult != nil,
            objectIDs.count == messages.count
      else {
        throw PsyError.batchInsertError
      }
    }
    
    try await context.perform {
      for emailID in objectIDs {
        let email = context.object(with: emailID) as! Email
        let _account = context.object(with: account.objectID) as! Account
        email.account = _account
        _account.addToEmails(email)
        
        if let bundleName = self.bundleNameForEmail(email) {
          let bundleFetchRequest = EmailBundle.fetchRequest()
          bundleFetchRequest.predicate = NSPredicate(format: "name == %@", bundleName)
          bundleFetchRequest.fetchLimit = 1
          bundleFetchRequest.fetchBatchSize = 1
          
          let bundle = try context.fetch(bundleFetchRequest).first!
          
          bundle.addToEmailSet(email)
          email.addToBundleSet(bundle)
        }
        
//        let threadFetchRequest = Email.fetchRequestWithProps("gmailThreadId", "isLatestInThread", "receivedDate")
//        threadFetchRequest.sortDescriptors = [NSSortDescriptor(key: "receivedDate", ascending: false)]
//        threadFetchRequest.predicate = NSPredicate(format: "gmailThreadId == %d", Int64(message.gmailThreadID))
//
//        let emailsInThread = try context.fetch(threadFetchRequest) as [Email]
//        emailsInThread.forEach { $0.isLatestInThread = false }
//        emailsInThread.first?.isLatestInThread = true
      }
    }
  }
  
  
  private func highestEmailUid() -> UInt64 {
    let request: NSFetchRequest<Email> = Email.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "uid", ascending: false)]
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    request.propertiesToFetch = ["uid"]

    return UInt64(try! moc.fetch(request).first?.uid ?? 0)
  }
  
  private
  func fetchEmailByUid(_ uid: UInt32, account: Account) -> Email? {
    let fetchRequest: NSFetchRequest<Email> = Email.fetchRequest()
    fetchRequest.predicate = NSPredicate(
      format: "uid == %d && account.address == %@",
      Int32(uid), account.address
    )
    do {
      return try moc.fetch(fetchRequest).first
    }
    catch {
      print("error fetching email by uid: \(error.localizedDescription)")
    }
    
    return nil
  }
  
  private
  func bundleNameForEmail(_ email: Email) -> String? {
    if email.gmailLabels.contains(cSentLabel) {
      // don't put sent emails in a bundle
      return nil
    }
    
    if let bundleLabel = email.gmailLabels.first(where: { $0.contains("psymail") }) {
      return bundleLabel.replacing("psymail/", with: "")
    }
    
    return "inbox"
  }
  
}


extension MailController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    update()
  }
  
}

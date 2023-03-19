import Foundation
import MailCore
import Combine
import SwiftUI
import CoreData


let DefaultFolder = "[Gmail]/All Mail" //"INBOX"
let cInboxLabel = "\\Inbox"
let cSentLabel = "\\Sent"
let cTrashLabel = "\\Trash"
let cDraftLabel = "\\Draft"

private let bundleCtrl = EmailBundleController.shared
private let accountCtrl = AccountController.shared
private let dataCtrl = PersistenceController.shared
private let moc = dataCtrl.container.viewContext


class MailController: NSObject, ObservableObject {
  static let shared = MailController()
  
  @Published private(set) var fetching = false
  @Published var threadsInSelectedBundle: [EmailThread] = []
  @Published var selectedThreads = Set<EmailThread>()

  private var subscribers: [AnyCancellable] = []
  private let threadCtrl: NSFetchedResultsController<EmailThread>
  private var sessions: [Account: MCOIMAPSession] {
    AccountController.shared.sessions
  }
  
  // MARK: -
  
  private override init() {
    let threadRequest = EmailThread.fetchRequestForBundle(bundleCtrl.selectedBundle)
    threadCtrl = NSFetchedResultsController(fetchRequest: threadRequest,
                                            managedObjectContext: moc,
                                            sectionNameKeyPath: nil,
                                            cacheName: nil) // TODO: cache?
    try? threadCtrl.performFetch()
    
    super.init()
    threadCtrl.delegate = self
    
    // update emails when selected bundle changes
    bundleCtrl.$selectedBundle
      .sink { selectedBundle in
        self.threadCtrl.fetchRequest.predicate = EmailThread.predicateForBundle(selectedBundle)
        try? self.threadCtrl.performFetch()
        self.update()
      }
      .store(in: &subscribers)
    
    subscribeToSyncedAccounts()
    update()
  }
  
  deinit {
    subscribers.forEach { $0.cancel() }
  }
  
  private func update() {
    DispatchQueue.main.async {
      print("updating email results")
      self.threadsInSelectedBundle = self.threadCtrl.fetchedObjects ?? []
    }
  }
  
  private func subscribeToSyncedAccounts() {
    accountCtrl.$signedInAccounts
      .sink { _ in
        Task { try? await self.fetchLatest() }
      }
      .store(in: &subscribers)
  }
  
  // MARK: - API
  
  func fetchLatest() async throws {
    DispatchQueue.main.async {
      self.fetching = true
    }

    for account in accountCtrl.signedInAccounts {
      try await self.fetchLatest(account)
    }
    
    // "load" for at least one second
    try? await Task.sleep(for: .seconds(1))

    print("done fetching!")
    DispatchQueue.main.async {
      UserDefaults.standard.set(Date.now.ISO8601Format(), forKey: "lastUpdated")
      self.fetching = false
    }
  }
  
  func moveThread(_ thread: EmailThread, fromBundle: EmailBundle, toBundle: EmailBundle, always: Bool = true) async throws {
    await moc.perform {
      // proactively update core data and revert if update request fails
      thread.bundle = toBundle
      fromBundle.removeFromThreadSet(thread)
      toBundle.addToThreadSet(thread)
      dataCtrl.save()
    }
    
    if toBundle.name == "inbox" {
      try await thread.removeLabels(["psymail/\(fromBundle.name)"])
      // TODO: delete filter
      return
    }
    
    do {
      try await thread.addLabels(["psymail/\(toBundle.name)"])
      try await thread.removeLabels([cInboxLabel])
    }
    catch {
      print(error.localizedDescription)
      await moc.perform {
        thread.bundle = fromBundle
        fromBundle.addToThreadSet(thread)
        toBundle.removeFromThreadSet(thread)
        dataCtrl.save()
      }
      // TODO: figure out UX
      throw error
    }
    
    if always {
      do {
        try await createFilterForThread(thread, bundle: toBundle)
      }
      catch {
        print("error creating bundle filter: \(error.localizedDescription)")
        throw error
      }
    }
  }
  
  private func createFilterForThread(_ thread: EmailThread, bundle: EmailBundle) async throws {
    let account = thread.account
    let address = thread.emails.first!.from.address // TODO: make this more robust
    
    var filterExistsForSameBundle = false
    var filterIdToDelete: String? = nil
    
    let (filterListResponse, _) = try await GmailEndpoint.call(.listFilters, forAccount: account)
    let filters = (filterListResponse as! GFilterListResponse).filter
    
    filters.forEach { filter in
      if let addLabelIds = filter.action?.addLabelIds ?? nil,
         let from = filter.criteria?.from ?? nil,
         from.contains(address) {
       
        if addLabelIds.contains(bundle.labelId) {
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
        "addLabelIds": [bundle.labelId],
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
            let context = moc//dataCtrl.newTaskContext()
            try await context.perform(schedule: .enqueued) {
              try self.onReceivedMessages(messages, forAccount: account, context: context)
            }
            dataCtrl.save()
            
            print("done saving new messages!")
            continuation.resume()
          }
          catch {
            print("error saving fetched messages: \(error.localizedDescription)")
            continuation.resume(throwing: error)
          }
        }
      }
    }
  }
  
  private func onReceivedMessages(_ messages: [MCOIMAPMessage]?, forAccount account: Account, context: NSManagedObjectContext
  ) throws {
    
    guard let messages = messages
    else { return }
    
    let _account = context.object(with: account.objectID) as! Account
    var newThreadsById = [Int64:EmailThread]()
    
    for message in messages {
      let email = Email(context: context)
      email.hydrateWithMessage(message)
      
      let threadRequest = EmailThread.fetchRequest(id: email.threadId)
      var thread = try? threadRequest.execute().first ?? newThreadsById[email.threadId]
      if thread == nil {
        thread = EmailThread(context: context)
        newThreadsById[email.threadId] = thread
      }
      
      guard let thread = thread else { throw PsyError.creationError }
      thread.hydrateWithMessage(message)
      thread.addToEmailSet(email)
      thread.account = _account
      
      email.thread = thread
      email.account = account
      
      _account.addToEmailSet(email)
      _account.addToThreadSet(thread)

      if let bundleName = self.bundleNameForEmail(email) {
        let bundleFetchRequest = EmailBundle.fetchRequest()
        bundleFetchRequest.predicate = NSPredicate(format: "name == %@", bundleName)
        bundleFetchRequest.fetchLimit = 1
        bundleFetchRequest.fetchBatchSize = 1

        let bundle = try bundleFetchRequest.execute().first!

        bundle.addToThreadSet(thread)
        thread.bundle = bundle

        if bundleCtrl.selectedBundle != bundle {
          bundle.newEmailsSinceLastSeen += 1
        }
      }

      print("\(email.uid) hydrated • \(email.subject)")
    }
  }
  
  private func onReceivedMessagesBatch(
    _ messages: [MCOIMAPMessage]?, forAccount account: Account, context: NSManagedObjectContext
  ) async throws {
    
    guard let messages = messages,
          messages.count > 0
    else { return }
    
    let threads = Dictionary(grouping: messages) { Int64($0.gmailThreadID) }.map { $0.value }
    var threadObjectIdsByThreadId = [Int64:NSManagedObjectID]()
    var index = 0
    
    let threadBatchInsertRequest = NSBatchInsertRequest(entity: EmailThread.entity(), managedObjectHandler: { managedObject in
      guard index < threads.count
      else { return true }

      let thread = managedObject as! EmailThread
      thread.hydrateWithMessage(threads[index].first!)
      threadObjectIdsByThreadId[thread.id] = thread.objectID
      
      index += 1
      return false
    })
    
    try await context.perform {
      let threadInsertResult = try context.execute(threadBatchInsertRequest) as? NSBatchInsertResult
      guard threadInsertResult != nil
      else {
        throw PsyError.batchInsertError
      }
    }
    
    index = 0
    let emailBatchInsertRequest = NSBatchInsertRequest(entity: Email.entity(), managedObjectHandler: { managedObject in
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

    var emailIDs = [NSManagedObjectID]()
    try await context.perform {
      let emailInsertResult = try context.execute(emailBatchInsertRequest) as? NSBatchInsertResult
      emailIDs = emailInsertResult?.result as? [NSManagedObjectID] ?? []

      guard emailInsertResult != nil,
            emailIDs.count == messages.count
      else {
        throw PsyError.batchInsertError
      }

      let _account = context.object(with: account.objectID) as! Account
      for emailID in emailIDs {
        let email = context.object(with: emailID) as! Email
        email.account = _account
        _account.addToEmailSet(email)

        let threadRequest = EmailThread.fetchRequest(id: email.threadId)
        guard let thread = try? threadRequest.execute().first
        else {
          print("error fetching thread for new email message: \(email.subject)")
          continue
        }

        thread.addToEmailSet(email)
        thread.lastMessageDate = email.receivedDate
        thread.subject = email.subject
        thread.account = _account
        email.thread = thread
        _account.addToThreadSet(thread)

        if let bundleName = self.bundleNameForEmail(email) {
          let bundleFetchRequest = EmailBundle.fetchRequest()
          bundleFetchRequest.predicate = NSPredicate(format: "name == %@", bundleName)
          bundleFetchRequest.fetchLimit = 1
          bundleFetchRequest.fetchBatchSize = 1

          let bundle = try bundleFetchRequest.execute().first!

          bundle.addToThreadSet(thread)
          thread.bundle = bundle

          if bundleCtrl.selectedBundle != bundle {
            bundle.newEmailsSinceLastSeen += 1
          }
        }

        print("\(email.uid) fully hydrated • \(email.subject)")
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
    if email.labels.contains(cSentLabel) || email.labels.contains(cDraftLabel) {
      // don't put sent or draft emails in a bundle
      return nil
    }
    
    if let bundleLabel = email.labels.first(where: { $0.contains("psymail") }) {
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

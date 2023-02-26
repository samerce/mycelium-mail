import Foundation
import MailCore
import Combine
import SwiftUI
import CoreData


let DefaultFolder = "[Gmail]/All Mail" //"INBOX"
let cInboxLabel = "\\Inbox"
private let kBundleIcons = [
  "notifications": "bell",
  "commerce": "creditcard",
  "inbox": "tray.full",
  "newsletters": "newspaper",
  "society": "building.2",
  "marketing": "megaphone"
]
private let moc = PersistenceController.shared.container.viewContext


class MailController: ObservableObject {
  static let shared = MailController()
  
  @Published var model: MailModel = MailModel()
  @Published private(set) var selectedEmail: Email?
  
  private var accountCtrl = AccountController.shared
  var sessions = [Account: MCOIMAPSession]()
  private var subscribers: [AnyCancellable] = []
  private var gmailLabelIdsByBundle: [String: String] = [:]
  
  private var animation: Animation {
    .interactiveSpring(response: 0.36, dampingFraction: 0.74)
  }
  
  private init() {
    for (address, account) in accountCtrl.model.accounts {
      account.$signedIn
        .sink { signedIn in
          print("\(address) signed in: \(signedIn)")
          
          if signedIn {
          } else {
            // handle log out
          }
        }
        .store(in: &subscribers)
    }
    
    // if "inbox" bundle doesn't exist, create it
    let bundleFetchRequest = EmailBundle.fetchRequestWithProps("name")
    let bundles = try? moc.fetch(bundleFetchRequest)
    if bundles?.first(where: { $0.name == "inbox" }) == nil {
      let _ = EmailBundle(name: "inbox", gmailLabelId: "", icon: kBundleIcons["inbox"]!, context: moc)
    }
  }
  
  func onSignedInAccount(_ account: Account) {
    var session = sessions[account]
    if session == nil {
      session = sessionForType(account.type)
      sessions[account] = session
    }
    session!.username = account.address
    session!.oAuth2Token = account.accessToken
    session!.isVoIPEnabled = false
    
    Task(priority: .background) {
      // gotta sync bundles before fetch, cuz on first start
      // the bundles must exist while emails are being created
      do {
        try await self.syncEmailBundles(account)
      }
      catch {
        print("failed to sync email bundles: \(error.localizedDescription)")
      }
      
      try? await self.fetchLatest(account)
    }
  }
  
  private func syncEmailBundles(_ account: Account) async throws {
    let bundleFetchRequest = EmailBundle.fetchRequestWithProps("name", "gmailLabelId")
    let bundles = try? moc.fetch(bundleFetchRequest)
    
    let (labelListResponse, _) = try await GmailEndpoint.call(.listLabels, forAccount: account)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    // TODO: use batch insert?
    labels.forEach { label in
      if !label.name.contains("psymail/") {
        return
      }
      
      let bundleName = label.name.replacing("psymail/", with: "")
      var bundle = bundles?.first(where: { $0.name == bundleName })
      if bundle == nil {
        bundle = EmailBundle(
          name: bundleName, gmailLabelId: label.id, icon: kBundleIcons[bundleName] ?? "", context: moc
        )
      } else {
        // TODO: update this to work with multiple accounts
        bundle!.gmailLabelId = label.id
      }
    }
    
    PersistenceController.shared.save()
  }
  
  // MARK: - public
  
  func moveEmail(_ email: Email, fromBundle: EmailBundle, toBundle: EmailBundle, always: Bool = true) async throws {
    // proactively update core data and revert if update request fails
    email.removeFromBundleSet(fromBundle)
    email.addToBundleSet(toBundle)
    fromBundle.removeFromEmailSet(email)
    toBundle.addToEmailSet(email)
    PersistenceController.shared.save()
    
    if toBundle.name == "inbox" {
      try await self.removeLabels(["psymail/\(fromBundle.name)"], fromEmails: [email])
      // TODO: delete filter
      return
    }
    
    do {
      try await self.addLabels(["psymail/\(toBundle.name)"], toEmails: [email])
      try await self.removeLabels([cInboxLabel], fromEmails: [email])
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
  
  func createLabel(_ name: String, forAccount account: Account) async throws -> GLabel {
    let (labelListResponse, _) = try await GmailEndpoint.call(.listLabels, forAccount: account)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    if let label = labels.first(where: { $0.name == name }) {
      print("label exists, skipping creation")
      return label
    }
    
    let (label, _) = try await GmailEndpoint.call(.createLabel, forAccount: account, withBody: [
      "name": name,
      "labelListVisibility": "labelShow",
      "messageListVisibility": "show",
      "type": "user"
    ])
    return (label as! GLabel)
  }
  
  func markSeen(_ emails: [Email], _ completion: @escaping ([Error]?) -> Void) {
    addFlags(.seen, for: emails) { errors in
      if let errors = errors, !errors.isEmpty {
        completion(errors)
      } else {
        completion(nil)
      }
    }
  }
  
  func deleteEmails(_ emails: [Email]) {
    moveEmailsToTrash(emails) { error in
      if error != nil {
        // let view know
        return
      }
      
      self.model.deleteEmails(emails) { error in
        if error != nil {
          // let view know
        }
      }
    }
  }
  
  func flagEmails(_ emails: [Email]) {
    addFlags(.flagged, for: emails) { errors in
      if let errors = errors, !errors.isEmpty {
        // tell view about it
      }
    }
  }
  
  func selectEmail(_ email: Email) {
    withAnimation(animation) { selectedEmail = email }
  }
  
  func deselectEmail() {
    withAnimation(animation) { selectedEmail = nil }
  }
  
  func fetchLatest() async throws {
    sessions.forEach { value in
      Task { try await fetchLatest(value.key) }
    }
  }
  
  // MARK: - private
  
  private func fetchLatest(_ account: Account) async throws {
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
    
    let _:Any? = try await withCheckedThrowingContinuation { continuation in
      fetchHeadersAndFlags?.start {
        (error: Error?, messages: [MCOIMAPMessage]?, vanishedMessages: MCOIndexSet?) in
        if let error = error {
          continuation.resume(throwing: PsyError.unexpectedError(error))
          return
        }
        
        if messages?.count == 0 {
          print("done fetching!")
        }
        
        if messages != nil {
          self.saveMessages(messages!, account: account)
        }
        continuation.resume(returning: nil)
      }
    }
  }
  
  private var errors: [Error] = []
  
  private func addFlags(_ flags: MCOMessageFlag, for theEmails: [Email],
                        _ completion: ([Error]?) -> Void) {
    print("adding flags")
    let queue = OperationQueue()
    
    for (account, theEmails) in emailsByAccount(theEmails) {
      let session = sessions[account]!
      guard let updateFlags = session.storeFlagsOperation(
        withFolder: DefaultFolder,
        uids: uidSetForEmails(theEmails),
        kind: .add,
        flags: flags
      ) else {
        // TODO append an error
        print("error creating update flags operation")
        continue
      }
      
      queue.addBarrierBlock {
        updateFlags.start { _error in
          if let _error = _error {
            print("error setting flags: \(_error.localizedDescription)")
            self.errors.append(_error)
            return
          }
          
          Task {
            do {
              try await self.model.addFlags(flags, for: theEmails)
            } catch {
              self.errors.append(error)
            }
          }
        }
      }
    }
    
    queue.waitUntilAllOperationsAreFinished()
    completion(errors.isEmpty ? nil : errors)
  }
  
  func addLabels(_ labels: [String], toEmails emails: [Email]) async throws {
    for email in emails {
      try await addLabels(labels, toEmail: email)
    }
  }
  
  func addLabels(_ labels: [String], toEmail email: Email) async throws {
    let session = sessions[email.account!]!
    
    guard let addLabels = session.storeLabelsOperation(
      withFolder: DefaultFolder,
      uids: uidSetForEmails([email]),
      kind: .add,
      labels: labels
    ) else {
      throw PsyError.labelUpdateFailed(message: "error creating addLabel operation")
    }
    
    let _: Any? = try await withCheckedThrowingContinuation { continuation in
      addLabels.start { _error in
        if let _error = _error {
          self.errors.append(_error)
          continuation.resume(throwing: PsyError.labelUpdateFailed(_error))
          return
        }
        
        labels.forEach { label in
          email.gmailLabels.insert(label)
        }
        continuation.resume(returning: nil)
      }
    }
  }
  
  func removeLabels(_ labels: [String], fromEmails emails: [Email]) async throws {
    for email in emails {
      try await removeLabels(labels, fromEmail: email)
    }
  }
  
  func removeLabels(_ labels: [String], fromEmail email: Email) async throws {
    let session = sessions[email.account!]!
    
    guard let removeLabels = session.storeLabelsOperation(
      withFolder: DefaultFolder,
      uids: uidSetForEmails([email]),
      kind: .remove,
      labels: labels
    ) else {
      throw PsyError.labelUpdateFailed(message: "error creating removeLabel operation")
    }
    
    let _: Any? = try await withCheckedThrowingContinuation { continuation in
      removeLabels.start { _error in
        if let _error = _error {
          self.errors.append(_error)
          continuation.resume(throwing: PsyError.labelUpdateFailed(_error))
          return
        }
        
        labels.forEach { label in
          email.gmailLabels.remove(label)
        }
        continuation.resume(returning: nil)
      }
    }
  }
  
  private func moveEmailsToTrash(_ emails: [Email],
                                 _ completion: @escaping (Error?) -> Void) {
    print("moving emails to trash")
    let queue = OperationQueue()
    var errors = [Error]()
    
    for (account, emails) in emailsByAccount(emails) {
      let uids = uidSetForEmails(emails)
      guard let session = sessions[account],
            let addTrashLabel = session.storeLabelsOperation(
              withFolder: DefaultFolder,
              uids: uids,
              kind: .add,
              labels: ["\\Trash"]),
            let expunge = session.expungeOperation("INBOX")
      else {
        // TODO append an error
        print("error creating session operations")
        continue
      }

      queue.addBarrierBlock {
        addTrashLabel.start { error in
          if let error = error {
            print("error adding trash label: \(error.localizedDescription)")
            errors.append(error)
          }
        }
      }
      
      queue.addBarrierBlock {
        expunge.start { error in
          if let error = error {
            print("error expunging: \(error.localizedDescription)")
            errors.append(error)
          }
        }
      }
      
    }
    
    queue.waitUntilAllOperationsAreFinished()
    completion(errors.isEmpty ? nil : errors[0]) // TODO send all back?
  }
  
  private func emailsByAccount(_ emails: [Email]) -> [Account: [Email]] {
    var result = [Account: [Email]]()
    
    for email in emails {
      guard let account = email.account else { continue }
      
      if result[account] == nil {
        result[account] = []
      }
      
      result[account]!.append(email)
    }
    
    return result
  }
  
  private func uidSetForEmails(_ emails: [Email]) -> MCOIndexSet {
    let uidSet = MCOIndexSet()
    for email in emails {
      uidSet.add(UInt64(email.uid))
    }
    return uidSet
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
  
  func fetchHtml(for email: Email) async throws {
    guard email.html.isEmpty
    else { return }
    
    email.html = try await self.bodyHtmlForEmail(email)
    
    try await moc.perform {
      try moc.save()
    }
  }
  
  func bodyHtmlForEmail(_ email: Email) async throws -> String {
    let session = sessions[email.account!]!
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: DefaultFolder, uid: UInt32(email.uid))
    
    return try await withCheckedThrowingContinuation { continuation in
      guard let fetchMessage = fetchMessage else {
        continuation.resume(
          throwing: PsyError.unexpectedError(message: "failed to create fetch HTML operation")
        )
        return
      }
      
      fetchMessage.start() { (error: Error?, parser: MCOMessageParser?) in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: parser?.htmlBodyRendering() ?? "")
        }
      }
    }
  }
  
  func fullHtmlForEmail(withUid uid: UInt32, account: Account, _ completion: @escaping (String?) -> Void) {
    let session = sessions[account]!
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: DefaultFolder, uid: uid)
    fetchMessage?.start() { (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlRendering(with: nil) ?? "")
    } ?? completion("")
  }
  
  
}

class GmailSession: MCOIMAPSession {
  
  override init() {
    super.init()
    hostname = "imap.gmail.com"
    port = 993
    authType = .xoAuth2
    connectionType = .TLS
    allowsFolderConcurrentAccessEnabled = true
  }
  
}

private func sessionForType(_ accountType: AccountType) -> MCOIMAPSession {
  switch accountType {
  case .gmail:
    return GmailSession()
  }
}

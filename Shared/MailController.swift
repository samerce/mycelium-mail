import Foundation
import MailCore
import Combine
import SwiftUI
import CoreData


let DefaultFolder = "[Gmail]/All Mail" //"INBOX"


class MailController: ObservableObject {
  static let shared = MailController()
  
  @Published var model: MailModel = MailModel()
  @Published private(set) var selectedEmail: Email?
  
  private var accountCtrl = AccountController.shared
  private var sessions = [Account: MCOIMAPSession]()
  private var subscribers: [AnyCancellable] = []
  private var gmailLabelIdsByBundle: [String: String] = [:]
  private var selectedAccount: Account?
  private var accessToken: String = ""
  
  private var animation: Animation {
    .interactiveSpring(response: 0.36, dampingFraction: 0.74)
  }
  
  private init() {
    for (address, account) in accountCtrl.model.accounts {
      account.$loggedIn
//        .receive(on: RunLoop.main)
        .sink { loggedIn in
          print("\(address) loggedIn: \(loggedIn)")
          
          if loggedIn {
            self.onLoggedIn(account)
            self.selectedAccount = account
            self.accessToken = account.accessToken!
            Task { await self.fetchGmailLabelIds() }
          } else {
            // handle log out
          }
        }
        .store(in: &subscribers)
    }
  }
  
  private func fetchGmailLabelIds() async {
    do {
      let (labelListResponse, _) = try await callGmail(.listLabels)
      let labels = (labelListResponse as! GLabelListResponse).labels
      
      labels.forEach { label in
        if label.name.contains("psymail/") {
          let bundle = label.name.replacing("psymail/", with: "")
          self.gmailLabelIdsByBundle[bundle] = label.id
        }
      }
    }
    catch {
      print("failed to fetch labels: \(error.localizedDescription)")
    }
  }
  
  // MARK: - public
  
  func moveEmail(_ email: Email, toBundle bundle: String, always: Bool = true) throws {
    // proactively update core data and revert if update request fails
    let originalBundle = email.perspective
    email.perspective = bundle
    PersistenceController.shared.save()
    
    Task {
      do {
        try await self.addLabels(["psymail/\(bundle)"], toEmails: [email])
      }
      catch {
        print("failed to add bundle label: \(error.localizedDescription)")
        email.perspective = originalBundle
        PersistenceController.shared.save()
        // TODO: figure out UX
        throw error
      }
      
      if always {
        do {
          try await createFilterFor(email: email, bundle: bundle)
        }
        catch {
          print("error creating bundle filter: \(error.localizedDescription)")
          throw error
        }
      }
    }
  }
  
  private func createFilterFor(email: Email, bundle: String) async throws {
    guard let address = email.from?.address
    else {
      throw PsyError.unexpectedError(message: "email had no 'from' address to create filter with")
    }
    
    var filterExistsForSameBundle = false
    var filterIdToDelete: String? = nil
    
    let (filterListResponse, _) = try await callGmail(.listFilters)
    let filters = (filterListResponse as! GFilterListResponse).filter
    
    filters.forEach { filter in
      if let addLabelIds = filter.action?.addLabelIds ?? nil,
         let from = filter.criteria?.from ?? nil,
         from.contains(address) {
       
        if addLabelIds.contains("psymail/\(bundle)") {
          filterExistsForSameBundle = true
        } else {
          // filter exists for diff bundle so delete it and create the new filter
          filterIdToDelete = filter.id
        }
      }
    }
    
    if filterExistsForSameBundle {
      print("filter already exists to send \(address) to \(bundle), skipping")
      return
    }
    
    if let id = filterIdToDelete {
      print("filter already exists to send \(address) to a different bundle; deleting existing filter")
      try await callGmail(.deleteFilter(id: id))
    }
    
    print("creating filter for \(address) to \(bundle)")
    try await callGmail(.createFilter, withBody: [
      /// see:  https://developers.google.com/gmail/api/guides/filter_settings
      "criteria": [
        "from": address,
      ],
      "action": [
        "addLabelIds": [gmailLabelIdsByBundle[bundle]!],
        "removeLabelIds": ["INBOX", "SPAM"] // skip the inbox, never send to spam
      ]
    ])
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
  
  func fetchMore(_ bundle: String) {
    model.fetchMore(bundle)
  }
  
  func fetchLatest() async throws {
    sessions.forEach { value in
      Task { try await fetchLatest(value.key) }
    }
  }
  
  // MARK: - private
  
  @discardableResult
  private func callGmail(
    _ endpoint: GmailEndpoint, withBody body: Any? = nil
  ) async throws -> (Decodable, URLResponse) {
    return try await GmailEndpoint.call(endpoint, accessToken: selectedAccount!.accessToken!, withBody: body)
  }
  
  private func onLoggedIn(_ account: Account) {
    var session = sessions[account]
    if session == nil {
      session = sessionForType(account.type)
      sessions[account] = session
    }
    
    session!.username = account.address
    session!.oAuth2Token = account.accessToken
    session?.isVoIPEnabled = false
    
    Task(priority: .background) {
      try? await self.fetchLatest(account)
    }
  }
  
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
    let session = sessions[selectedAccount!]!
    guard let addLabels = session.storeLabelsOperation(
      withFolder: DefaultFolder,
      uids: uidSetForEmails(emails),
      kind: .add,
      labels: labels
    ) else {
      throw PsyError.addLabelFailed(message: "error creating addLabel operation")
    }
    
    let _: Any? = try await withCheckedThrowingContinuation { continuation in
      addLabels.start { _error in
        if let _error = _error {
          self.errors.append(_error)
          continuation.resume(throwing: PsyError.addLabelFailed(_error))
        }
        
        emails.forEach { email in
          labels.forEach { label in
            email.gmailLabels!.insert(label)
          }
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
      self.model.makeAndSaveEmail(withMessage: message, account: account)
      
      if message == messages.last {
        print("done saving!")
      }
      
//      bodyHtmlForEmail(withUid: message.uid, account: account) { emailAsHtml in
//        self.model.makeAndSaveEmail(
//          withMessage: message, html: emailAsHtml, account: account
//        )
//
//        if message == messages.last {
//          print("done saving!")
//        }
//      }
    }
  }
  
  func fetchHtml(for email: Email) async throws {
    let context = PersistenceController.shared.newTaskContext()
    context.name = "fetchHtml"
    context.transactionAuthor = "MailController"
    
    if email.html == nil || email.html!.isEmpty {
      email.html = try await self.bodyHtmlForEmail(withUid: UInt32(email.uid), account: email.account!)
    }
  
    try await context.perform {
      try context.save()
    }
  }
  
  func bodyHtmlForEmail(withUid uid: UInt32, account: Account) async throws -> String {
    let session = sessions[account]!
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: DefaultFolder, uid: uid)
    
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

private class GmailSession: MCOIMAPSession {
  
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

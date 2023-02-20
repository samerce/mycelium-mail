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
          } else {
            // handle log out
          }
        }
        .store(in: &subscribers)
    }
  }
  
  // MARK: - public
  
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
    deselectEmail()
    moveEmailsToTrash(emails) { error in
      if error != nil {
        // let view know
        return
      }
      
      Timer.scheduledTimer(withTimeInterval: 0.36, repeats: false) { _ in
        withAnimation(self.animation) {
          self.model.deleteEmails(emails) { error in
            if error != nil {
              // let view know
            }
          }
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
  
  func fetchLatest() {
    sessions.forEach { value in
      fetchLatest(value.key)
    }
  }
  
  // MARK: - private
  
  private func onLoggedIn(_ account: Account) {
    var session = sessions[account]
    if session == nil {
      session = sessionForType(account.type)
      sessions[account] = session
    }
    
    session!.username = account.address
    session!.oAuth2Token = account.accessToken
    session?.isVoIPEnabled = false
    fetchLatest(account)
  }
  
  private func fetchLatest(_ account: Account) {
    let startUid = model.lastSavedEmailUid + 1
    let endUid = UInt64.max - startUid
    let uids = MCOIndexSet(range: MCORangeMake(startUid, endUid))
    
    print("fetching — startUid: \(startUid), endUid: \(endUid)")
    
    let session = sessions[account]!
    let fetchHeadersAndFlags = session.fetchMessagesOperation(
      withFolder: DefaultFolder,
      requestKind: [.fullHeaders, .flags, .gmailLabels, .gmailThreadID, .gmailMessageID],
      uids: uids
    )
    
    fetchHeadersAndFlags?.start {
    (error: Error?, messages: [MCOIMAPMessage]?, vanishedMessages: MCOIndexSet?) in
      if let error = error {
        print("error downloading message headers: \(error.localizedDescription)")
        return
      }
      
      if messages?.count == 0 {
        print("done fetching!")
      }
      
      if messages != nil {
        self.saveMessages(messages!, account: account)
//        Task {
//          try await self.model.saveNewMessages(messages!, forAccount: account)
//        }
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
    
    await context.perform {
      Task {
        let _email = context.object(with: email.objectID) as! Email
        _email.html = try await self.bodyHtmlForEmail(withUid: UInt32(email.uid), account: email.account!)
        try context.save()
      }
      return
    }
  }
  
  func bodyHtmlForEmail(withUid uid: UInt32, account: Account) async throws -> String {
    let session = sessions[account]!
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: DefaultFolder, uid: uid)
    
    return try await withCheckedThrowingContinuation { continuation in
      guard let fetchMessage = fetchMessage else {
        continuation.resume(returning: "")
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

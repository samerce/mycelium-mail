import Foundation
import MailCore
import Combine
import SwiftUI

class MailController: ObservableObject {
  static let shared = MailController()
  
  @Published var model: MailModel = MailModel()
  
  private var accountCtrl = AccountController.shared
  private var sessions = [Account: MCOIMAPSession]()
  private var subscribers: [AnyCancellable] = []
  
  private var animation: Animation {
    .interactiveSpring(response: 0.36, dampingFraction: 0.74)
  }
  
  private init() {
    for (address, account) in accountCtrl.model.accounts {
      account.$loggedIn
        .receive(on: RunLoop.main)
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
  
  func fetchLatest(_ account: Account) {
    let startUid = model.lastSavedEmailUid + 1
    let endUid = UINT64_MAX - startUid
    let uids = MCOIndexSet(range: MCORangeMake(startUid, endUid))
    
    print("fetching — startUid: \(startUid), endUid: \(endUid)")
    
    let session = sessions[account]!
    let fetchHeadersAndFlags = session.fetchMessagesOperation(
      withFolder: "INBOX", requestKind: [.fullHeaders, .flags], uids: uids
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
      }
    }
  }
  
  func markSeen(_ emails: [Email], _ completion: @escaping ([Error]?) -> Void) {
    setFlags(.seen, for: emails) { errors in
      if let errors = errors, !errors.isEmpty {
        completion(errors)
      } else {
        completion(nil)
      }
    }
  }
  
  func deleteEmails(_ emails: [Email]) {
    model.deleteEmails(emails) { error in
      if error != nil {
        // tell view about it
      } else {
        self.deselectEmail()
      }
    }
  }
  
  func flagEmails(_ emails: [Email]) {
    setFlags(.flagged, for: emails) { errors in
      if let errors = errors, !errors.isEmpty {
        // tell view about it
      }
    }
  }
  
  func selectEmail(_ email: Email) {
    withAnimation(animation) { model.selectedEmail = email }
  }
  
  func deselectEmail() {
    withAnimation(animation) { model.selectedEmail = nil }
  }
  
  // MARK: - private
  
  private func onLoggedIn(_ account: Account) {
    let session = sessionForType(account.type)
    session.username = account.address
    session.oAuth2Token = account.accessToken
    self.sessions[account] = session

    fetchLatest(account)
  }
  
  private func setFlags(_ flags: MCOMessageFlag, for _emails: [Email],
                _ completion: ([Error]?) -> Void) {
    let queue = OperationQueue()
    var errors = [Error]()
    
    for (account, emails) in emailsByAccount(_emails) {
      let session = sessions[account]!
      guard let updateFlags = session.storeFlagsOperation(
        withFolder: "INBOX", uids: uidSetForEmails(emails),
        kind: .set, flags: flags
      ) else {
        completion([]) // TODO set error
        return
      }
      
      queue.addBarrierBlock {
        updateFlags.start { error in
          if let error = error {
            print("error setting flags: \(error.localizedDescription)")
            errors.append(error)
            return
          }
            
          self.model.setFlags(flags, for: emails) { error in
            if let error = error {
              print("error setting flags in core data: \(error)")
              errors.append(error)
            }
          }
        }
      }
    }
    
    queue.waitUntilAllOperationsAreFinished()
    completion(errors.isEmpty ? nil : errors)
  }
  
  private func emailsByAccount(_ emails: [Email]) -> [Account: [Email]] {
    var result = [Account: [Email]]()
    
    for email in emails {
      var emailList: [Email]? = result[email.account!]
      if emailList == nil {
        emailList = []
        result[email.account!] = emailList
      }
      emailList!.append(email)
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
      bodyHtmlForEmail(withUid: message.uid, account: account) { emailAsHtml in
        self.model.makeAndSaveEmail(
          withMessage: message, html: emailAsHtml, account: account
        )
        
        if message == messages.last {
          print("done fetching!")
        }
      }
    }
  }
  
  func bodyHtmlForEmail(withUid uid: UInt32, account: Account, _ completion: @escaping (String?) -> Void) {
    let session = sessions[account]!
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
    fetchMessage?.start() { (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlBodyRendering() ?? "")
    } ?? completion("")
  }
  
  func fullHtmlForEmail(withUid uid: UInt32, account: Account, _ completion: @escaping (String?) -> Void) {
    let session = sessions[account]!
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
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
  }
  
}

private func sessionForType(_ accountType: AccountType) -> MCOIMAPSession {
  switch accountType {
  case .gmail:
    return GmailSession()
  }
}

//
//  MailController.swift
//  psymail
//
//  Created by bubbles on 5/28/21.
//

import Foundation
import MailCore
import Combine

class MailController: ObservableObject {
  static let shared = MailController()
  
  @Published var model: MailModel = MailModel()
  
  private var accountCtrl = AccountController.shared
  private var session: MCOIMAPSession = MCOIMAPSession()
  var subscribers: [AnyCancellable] = []
  
  private init() {
    session.hostname = "imap.gmail.com"
    session.port = 993
    session.authType = .xoAuth2
    session.connectionType = .TLS
    
    accountCtrl.$loggedIn
      .receive(on: RunLoop.main)
      .sink { loggedIn in
        print("loggedIn: \(loggedIn)")
        if loggedIn {
          self.session.username = self.accountCtrl.username
          self.session.oAuth2Token = self.accountCtrl.oAuthToken
          self.fetchLatest()
        } else {
          // handle log out
        }
      }
      .store(in: &subscribers)
  }
  
  // MARK: - public
  
  func fetchLatest() {
    print("fetching")
    
    let startUid = model.mostRecentSavedUid + 1
    let endUid = UINT64_MAX - model.mostRecentSavedUid - 1
    let uids = MCOIndexSet(range: MCORangeMake(startUid, endUid))
    
    let fetchHeadersAndFlags = session.fetchMessagesOperation(
      withFolder: "INBOX", requestKind: [.fullHeaders, .flags], uids: uids
    )
    fetchHeadersAndFlags?.start(onReceiveHeadersAndFlags)
  }
  
  func markSeen(_ emails: [Email], _ completion: @escaping (Error?) -> Void) {
    let uidSet = MCOIndexSet()
    for email in emails {
      uidSet.add(UInt64(email.uid))
    }
    
    let updateFlags = session.storeFlagsOperation(
      withFolder: "INBOX", uids: uidSet, kind: .set, flags: .seen
    )
    updateFlags?.start { error in
      if let error = error {
        print("error updating seen flag: \(error.localizedDescription)")
        completion(error)
        return
      }
      
      completion(self.model.markSeen(emails))
      
    } ?? print("error updating seen flag: couldn't create operation.")
  }
  
//  func setFlags(uids: IndexSet, flags: [])
  
  // MARK: - private
  
  func onReceiveHeadersAndFlags(
    error: Error?, messages: [MCOIMAPMessage]?, vanishedMessages: MCOIndexSet?
  ) {
    if let error = error {
      print("error downloading message headers: \(error.localizedDescription)")
      return
    }
    
    if messages == nil || messages?.count == 0 {
      print("done fetching!")
    }
    
    for message in messages! {
      bodyHtmlForEmail(withUid: message.uid) { emailAsHtml in
        self.model.makeAndSaveEmail(withMessage: message, html: emailAsHtml)
        
        if message == messages?.last {
          print("done fetching!")
        }
      }
    }
  }
  
  func bodyHtmlForEmail(withUid uid: UInt32, _ completion: @escaping (String?) -> Void) {
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
    fetchMessage?.start() { (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlBodyRendering() ?? "")
    } ?? completion("")
  }
  
  func fullHtmlForEmail(withUid uid: UInt32, _ completion: @escaping (String?) -> Void) {
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
    fetchMessage?.start() { (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlRendering(with: nil) ?? "")
    } ?? completion("")
  }
  
}

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
  
  private var accountCtrl = AccountController.shared
  private var session: MCOIMAPSession = MCOIMAPSession()
  private var subscribers: [AnyCancellable] = []
  
  var model: MailModel = MailModel()
  
  private init() {
    session.hostname = "imap.gmail.com"
    session.port = 993
    session.authType = .xoAuth2
    session.connectionType = .TLS
    
    accountCtrl.$loggedIn
      .receive(on: DispatchQueue.main)
      .sink { loggedIn in
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
    
    let uids = MCOIndexSet(range: MCORangeMake(model.mostRecentSavedUid, UINT64_MAX))
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
      if error != nil {
        print("error updating seen flag: \(String(describing: error))")
        return
      }
      
      completion(error)
      
    } ?? print("error updating seen flag: couldn't create operation.")
  }
  
//  func setFlags(uids: IndexSet, flags: [])
  
  // MARK: - private
  
  func onReceiveHeadersAndFlags(
    error: Error?, messages: [MCOIMAPMessage]?, vanishedMessages: MCOIndexSet?
  ) {
    if error != nil {
      print("Error downloading message headers: \(String(describing: error))")
      return
    }
    
    for message in messages! {
      htmlForEmail(withUid: message.uid) { emailAsHtml in
        self.model.makeAndSaveEmail(withMessage: message, html: emailAsHtml)
        
        if message == messages?.last {
          print("done fetching!")
        }
      }
    }
  }
  
  func htmlForEmail(withUid uid: UInt32, _ completion: @escaping (String?) -> Void) {
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
    fetchMessage?.start() { (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlRendering(with: nil) ?? "")
    } ?? completion("")
  }
  
}

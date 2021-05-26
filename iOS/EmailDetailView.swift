//
//  MessageView.swift
//  psymail (iOS)
//
//  Created by bubbles on 5/17/21.
//

import SwiftUI
import MailCore

struct EmailDetailView: View {
  @EnvironmentObject var model: MailModel
  
  private var email: Email
  @State private var emailAsHtml: String = ""
  @State private var seenTimer: Timer?
  
  init(_ email: Email) {
    self.email = email
  }
  
  var body: some View {
    VStack {
      WebView(emailAsHtml)
        .navigationBarTitle(Text(""), displayMode: .inline)
        .background(Color(.systemBackground))
  //      .navigationBarTitle("")
  //      .navigationBarBackButtonHidden(true)
    }
    .ignoresSafeArea()
    .onAppear {
      model.bodyHtmlFor(email.message) { html in
        emailAsHtml = html ?? ""
      }
      
      seenTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        seenTimer = nil
        model.markSeen(email)
      }
    }
    .onDisappear {
      seenTimer?.invalidate()
    }
  }
  
}

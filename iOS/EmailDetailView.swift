//
//  MessageView.swift
//  psymail (iOS)
//
//  Created by bubbles on 5/17/21.
//

import SwiftUI
import MailCore

struct EmailDetailView: View {
  var email: Email
  
  @EnvironmentObject private var model: MailModel
  @State private var emailAsHtml: String = ""
  @State private var seenTimer: Timer?
  
  var body: some View {
    VStack {
      WebView(content: emailAsHtml)
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
      seenTimer = nil
    }
  }
  
}

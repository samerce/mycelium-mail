//
//  MessageView.swift
//  psymail (iOS)
//
//  Created by bubbles on 5/17/21.
//

import SwiftUI
import Postal

struct MessageView: View {
  @EnvironmentObject private var model: MailModel
  
  private var message: FetchResult
  @State private var messageAsHTML: String = ""
  
  init(_ _message: FetchResult) {
    message = _message
  }
  
  var body: some View {
    VStack {
      WebView(messageAsHTML)
        .navigationBarTitle(Text(""), displayMode: .inline)
        .background(Color(.systemBackground))
  //      .navigationBarTitle("")
  //      .navigationBarBackButtonHidden(true)
        .onAppear {
          model.getMessage(message.uid) { msg in
            messageAsHTML = model.htmlFor(msg)
          }
        }
    }
    .ignoresSafeArea()
  }
  
}

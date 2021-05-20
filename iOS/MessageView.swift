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
        .ignoresSafeArea()
        .navigationBarTitle(Text(""), displayMode: .inline)
        .background(Color.primary)
  //      .navigationBarTitle("")
  //      .navigationBarBackButtonHidden(true)
        .onAppear {
          messageAsHTML = model.htmlFor(message)
        }
    }
  }
  
}

//
//  MessageView.swift
//  psymail (iOS)
//
//  Created by bubbles on 5/17/21.
//

import SwiftUI

struct EmailDetailView: View {
  var email: Email
  
  @State private var seenTimer: Timer?
  private let mailCtrl = MailController.shared
  
  var body: some View {
    VStack {
      WebView(content: email.html ?? "")
        .navigationBarTitle(Text(""), displayMode: .inline)
        .background(Color(.systemBackground))
  //      .navigationBarTitle("")
  //      .navigationBarBackButtonHidden(true)
    }
    .ignoresSafeArea()
    .onAppear {
      seenTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        seenTimer = nil
        mailCtrl.markSeen([email]) { error in
          // tell person about error
        }
      }
    }
    .onDisappear {
      seenTimer?.invalidate()
      seenTimer = nil
    }
  }
  
}

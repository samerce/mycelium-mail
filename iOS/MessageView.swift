//
//  MessageView.swift
//  psymail (iOS)
//
//  Created by bubbles on 5/17/21.
//

import SwiftUI

struct MessageView: View {
  @EnvironmentObject private var model: MailModel
  
  private var uid: UInt
  @State private var message: String = ""
  
  init(_ messageUID: UInt) {
    uid = messageUID
  }
  
  var body: some View {
    ScrollView {
      Text(message)
        .onAppear {
          model.getMessage(uid) { msg in
            message = "\(msg)"
          }
        }
        .padding(.bottom, 122)
    }
  }
  
}

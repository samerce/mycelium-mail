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
    VStack {
      WebView(message)
        .ignoresSafeArea()
        .navigationBarTitle(Text(""), displayMode: .inline)
        .background(Color.primary)
  //      .navigationBarTitle("")
  //      .navigationBarBackButtonHidden(true)
        .onAppear {
          model.getMessage(uid) { msg in
            let htmlPart = msg.body?.allParts.first(where: { part in
              part.mimeType.subtype == "html"
            })
            if (htmlPart?.data != nil) {
              let rawDataAsHtmlString: String = String(data: (htmlPart?.data!.rawData)!, encoding: .utf8)!
              message = QuotedPrintable.decode(rawDataAsHtmlString)
            }
          }
        }
    }
  }
  
}

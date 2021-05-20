//
//  WebView.swift
//  psymail
//
//  Created by bubbles on 5/18/21.
//

import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
  let content: String
  var webView: WKWebView
  
  init(_ htmlContent: String) {
    content = htmlContent
    webView = WKWebView()
    webView.layoutMargins = UIEdgeInsets.zero
    webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 118, right: 0)
  }
  
  func makeUIView(context: Context) -> WKWebView {
    webView
  }
  
  func updateUIView(_ view: WKWebView, context: Context) {
    view.loadHTMLString(content, baseURL: nil)
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(webView)
  }
  
  class Coordinator: NSObject, WKNavigationDelegate {
    init(_ view: WKWebView) {
      super.init()
      view.navigationDelegate = self
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//      webView.frame.size.height = 1
      webView.frame.size = webView.scrollView.contentSize
    }
  }
  
}

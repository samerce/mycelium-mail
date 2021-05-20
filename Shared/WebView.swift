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
    webView.scrollView.backgroundColor = .systemBackground
    webView.backgroundColor = .systemBackground
    
    configure()
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
  
  var domPurifyConfiguration: String {
      return """
      {
      ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
      ADD_TAGS: ['proton-src', 'base'],
      ADD_ATTR: ['target', 'proton-src'],
      FORBID_TAGS: ['body', 'style', 'input', 'form', 'video', 'audio'],
      FORBID_ATTR: ['srcset']
      }
      """.replacingOccurrences(of: "\n", with: "")
  }
  private func configure() {
    let left = "@media (prefers-color-scheme: dark) {body {color: white;}}:root {color-scheme: light dark;}"
    let sanitizeRaw = """
    var style = document.createElement('style');
    style.type = 'text/css';
    style.appendChild(document.createTextNode('\
    @media (prefers-color-scheme: dark) {\
      html{filter: invert(1)  hue-rotate(.5turn);background: white;}\
      body{background: white;}\
      img {filter: invert(1)  hue-rotate(.5turn);}\
    }'));
    document.getElementsByTagName('head')[0].appendChild(style);

    var metaWidth = document.createElement('meta');
    metaWidth.name = "viewport";
    metaWidth.content = "width=device-width,initial-scale=1";
    var rects = document.body.getBoundingClientRect();
    var ratio = document.body.offsetWidth/document.body.scrollWidth;
    document.getElementsByTagName('head')[0].appendChild(metaWidth);

    var metaWidth = document.querySelector('meta[name="viewport"]');
    metaWidth.content = "width=device-width";
    var ratio = document.body.offsetWidth/document.body.scrollWidth;
    if (ratio < 1) {
        metaWidth.content = metaWidth.content + ", initial-scale=" + ratio + ", maximum-scale=3.0";
    } else {
        ratio = 1;
    };
    window.webkit.messageHandlers.loaded.postMessage({'height': ratio * document.body.scrollHeight});
    """
    
    let message = """
    var items = document.body.getElementsByTagName('*');
    for (var i = items.length; i--;) {
        if (items[i].style.getPropertyValue("height") == "100%") {
            items[i].style.height = "auto";
        };
    };

    window.webkit.messageHandlers.loaded.postMessage({'preheight': ratio * rects.height, 'clearBody': document.documentElement.outerHTML.toString()});
    """
    
    let sanitize = WKUserScript(
      source: sanitizeRaw + message, injectionTime: .atDocumentEnd, forMainFrameOnly: true
    )
    webView.configuration.userContentController.removeAllUserScripts()
    webView.configuration.userContentController.addUserScript(sanitize)
  }
  
  class Coordinator: NSObject, WKNavigationDelegate {
    init(_ webView: WKWebView) {
      super.init()
      webView.navigationDelegate = self
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.frame.size.height = 1
      webView.frame.size = webView.scrollView.contentSize
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
      } else {
        decisionHandler(.allow)
      }
    }
  }
  
}

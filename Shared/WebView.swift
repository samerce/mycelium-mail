import WebKit
import SwiftUI


struct WebView: UIViewRepresentable {
  let html: String
  @Binding var height: CGFloat
  
  
  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.layoutMargins = UIEdgeInsets.zero
    webView.scrollView.backgroundColor = .systemBackground
    webView.backgroundColor = .systemBackground
    webView.navigationDelegate = context.coordinator
    configure(webView)
    return webView
  }
  
  func updateUIView(_ view: WKWebView, context: Context) {
    view.loadHTMLString(html, baseURL: nil)
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
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
  
  private func configure(_ webView: WKWebView) {
//    let left = "@media (prefers-color-scheme: dark) {body {color: white;}}:root {color-scheme: light dark;}"
    
//    var style = document.createElement('style');
//    style.type = 'text/css';
//    style.appendChild(document.createTextNode('\
//    @media (prefers-color-scheme: dark) {\
//      :root {color-scheme: light dark;}\
//      body {color: white;}\
//    }'));
//    document.getElementsByTagName('head')[0].appendChild(style);
    let sanitizeRaw = """
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
    webView.configuration.userContentController.addUserScript(viewPortScript())
  }
  
  class Coordinator: NSObject, WKNavigationDelegate {
    
    var parent: WebView
    var heightSet: Bool = false
    
    init(_ parent: WebView) {
      self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.scrollView.isScrollEnabled = false
      
//      webView.evaluateJavaScript("window.getComputedStyle(document.body).backgroundColor") {
//        (backgroundColor, error) in
//          webView.backgroundColor = backgroundColor // convert from rgba to UIColor
//      }
      
      // thanks chatGPT!
      webView.evaluateJavaScript("document.readyState", completionHandler: { (result, error) in
        if !self.heightSet, error == nil, let readyState = result as? String, readyState == "complete" {
          webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (result, error) in
            if error == nil, let height = result as? CGFloat {
              // set the height of the web view based on the height of the content
              self.parent.height = height
              self.heightSet = true
            }
          })
        }
      })
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
  
  
  private func viewPortScript() -> WKUserScript {
    let viewPortScript = """
          var meta = document.createElement('meta');
          meta.setAttribute('name', 'viewport');
          meta.setAttribute('initial-scale', '1.0');
          meta.setAttribute('maximum-scale', '1.0');
          meta.setAttribute('minimum-scale', '1.0');
          meta.setAttribute('user-scalable', 'no');
          document.getElementsByTagName('head')[0].appendChild(meta);
      """
    return WKUserScript(source: viewPortScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
  }
  
}


//let viewPortScript = """
//      var meta = document.createElement('meta');
//      meta.setAttribute('name', 'viewport');
//      meta.setAttribute('content', 'width=device-width');
//      meta.setAttribute('initial-scale', '1.0');
//      meta.setAttribute('maximum-scale', '1.0');
//      meta.setAttribute('minimum-scale', '1.0');
//      meta.setAttribute('user-scalable', 'no');
//      document.getElementsByTagName('head')[0].appendChild(meta);
//  """

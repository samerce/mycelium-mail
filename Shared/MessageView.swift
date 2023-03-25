import SwiftUI


struct MessageView: View {
  var email: Email

  @State var html = ""
  @State var htmlHeight: CGFloat = .zero
  
  
  var body: some View {
    ZStack {
      if html.isEmpty {
        ProgressView()
          .controlSize(.large)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        WebView(html: html, height: $htmlHeight)
          .height(htmlHeight)
      }
    }
    .task {
      try? await email.fetchHtml() // TODO: handle error
      html = email.html // TODO: why is this local state necessary?
      
      let indexWhereReplyStarts = html.firstMatch(
        // TODO: make this way more robust
        of: /(<blockquote|<div class="gmail_quote|<div class="zmail_extra|<div class="moz-cite-prefix)/
      )?.range.lowerBound.utf16Offset(in: html) ?? 0
      // TODO: add button to expand and make these replies visible
      
      if indexWhereReplyStarts > 0 {
        html = String(html.dropLast(html.count - indexWhereReplyStarts))
        html = String(html.trimmingPrefix(/<br >/))
        html = html.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
  }
  
}

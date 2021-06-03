import SwiftUI
import UIKit

enum EmailListRowMode {
  case summary, details
}

private var mailCtrl = MailController.shared

struct EmailListRow: View {
  var email: Email
  var mode: EmailListRowMode? = .summary
  
  @StateObject var model = mailCtrl.model
  @State var expanded = false
  
  var body: some View {
    ZStack {
      VStack(alignment: .leading, spacing: mode == .summary ? 3 : 6) {
//        if mode == .details { Spacer().frame(height: 30) }
        
        HStack(alignment: .lastTextBaseline) {
          Text(email.fromLine)
            .if(mode == .summary) { view in
              view
                .font(.system(size: 15, weight: .bold))
                .lineLimit(1)
            }
            .if(mode == .details) { v in v.font(.system(size: 20, weight: .bold)) }
          Spacer()
          Text(email.displayDate ?? "")
            .font(.system(size: 12, weight: .light))
            .foregroundColor(Color.secondary)
            .if(mode == .details) { v in v.hidden().frame(width: 0) }
          Image(systemName: mode == .details ? "chevron.down" : "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.pink)
            .if(mode == .details) { v in v.frame(width: 18, height: 18) }
            .if(mode == .summary) { v in v.frame(width: 12, height: 12) }
            .offset(x: 0, y: 1)
        }
        .clipped()
        
        Text(email.subject)
          .if(mode == .summary) { view in
            view
              .font(.system(size: 15, weight: .light))
              .lineLimit(2)
          }
          .if(mode == .details) { view in
            view.font(.system(size: 20))
          }
      }
      .foregroundColor(Color.primary)
      .padding(.vertical, 12)
      .padding(.horizontal, 12)
      .if(mode == .details) { v in v.padding(.bottom, 6).padding(.horizontal, 20) }
    }
    .listRowInsets(.none)
    .contentShape(Rectangle())
    .if(!email.seen && mode == .summary) { view in
      view
        .overlay(RainbowGlowBorder().opacity(0.98))
        .background(VisualEffectBlur(blurStyle: .prominent))
        .cornerRadius(12)
    }
  }
  
}

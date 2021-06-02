import SwiftUI
import UIKit

enum EmailListRowMode {
  case summary, details
}

struct EmailListRow: View {
  var email: Email
  var mode: EmailListRowMode? = .summary
  
  @ObservedObject private var mailCtrl = MailController.shared
  
  var body: some View {
    ZStack {
      VStack(alignment: .leading, spacing: 3) {
        if mode == .details { Spacer().frame(height: 30) }
        
        HStack(alignment: .lastTextBaseline) {
          Text(email.fromLine)
            .font(.system(size: 15, weight: .bold))
            .lineLimit(1)
          Spacer()
          Text(email.displayDate)
            .font(.system(size: 12, weight: .light))
            .foregroundColor(Color.secondary)
          Image(systemName: "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.gray)
            .frame(width: 12, height: 12)
            .offset(x: 0, y: 1)
            .if(mode == .details) { view in view.hidden() }
        }
        .clipped()
        .if(mode == .details) { view in
          view
            .frame(height: 0)
            .hidden()
        }
        
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
      .padding(.vertical, mode == .summary ? 12 : 12)
      .padding(.horizontal, mode == .summary ? 12 : 20)
    }
    .listRowInsets(.none)
    .contentShape(Rectangle())
    .onTapGesture {
      if mode == .summary {
        mailCtrl.selectEmail(email)
      } else {
        mailCtrl.deselectEmail()
      }
    }
    .if(!email.seen && mode == .summary) { view in
      view
        .overlay(RainbowGlowBorder().opacity(0.98))
        .background(VisualEffectBlur(blurStyle: .prominent))
        .cornerRadius(12)
    }
    .if(mode == .details) { view in
      view
        .frame(alignment: .top)
        .background(VisualEffectBlur(blurStyle: .prominent))
//        .roundedCorners(12, corners: .bottomLeft)
//        .roundedCorners(12, corners: .bottomRight)
    }
  }
  
}

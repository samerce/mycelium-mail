import SwiftUI

enum EmailListRowMode {
  case summary, details
}

struct EmailListRow: View {
  var email: Email
  var mode: EmailListRowMode = .summary
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      if !email.seen && mode == .summary {
        Rectangle()
          .fill(Color.psyAccent)
          .frame(maxWidth: 2, maxHeight: 12)
          .padding(.top, 3)
          .cornerRadius(3)
      }
      VStack(alignment: .leading, spacing: mode == .summary ? 4 : 6) {
//        if mode == .details { Spacer().frame(height: 30) }
        
        HStack(alignment: .lastTextBaseline) {
          Text(email.fromLine)
            .font(.system(size: 15, weight: email.seen ? .bold : .black))
            .if(mode == .summary) { view in
              view
                .font(.system(size: 15, weight: .heavy))
                .lineLimit(1)
            }
            .if(mode == .details) { $0.font(.system(size: 20, weight: .bold)) }
          Spacer()
          Text(email.displayDate ?? "")
            .font(.system(size: 12, weight: .light))
            .foregroundColor(Color.secondary)
            .if(mode == .details) { $0.hidden().frame(width: 0) }
          Image(systemName: mode == .details ? "chevron.down" : "chevron.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(email.seen ? Color(.systemGray3) : .psyAccent)
            .if(mode == .details) { $0.frame(width: 18, height: 18) }
            .if(mode == .summary) { $0.frame(width: 12, height: 12) }
            .offset(x: 0, y: 1)
        }
        .clipped()
        
        Text(email.subject)
          .if(mode == .summary) { view in
            view
              .font(.system(size: 15, weight: .light))
              .lineLimit(2)
          }
          .if(mode == .details) { $0.font(.system(size: 20)) }
          .truncationMode(.tail)
          .lineLimit(1)
      }
      .foregroundColor(Color.primary)
      .padding(.leading, 6)
      .padding(.trailing, 9)
      .if(mode == .details) { $0.padding(.bottom, 6).padding(.horizontal, 20) }
    }
    .frame(height: 54)
    .listRowInsets(.init())
    .contentShape(Rectangle())
  }
  
}

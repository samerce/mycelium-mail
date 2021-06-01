//
//  EmailListView.swift
//  psymail
//
//  Created by bubbles on 5/28/21.

import SwiftUI

private let oneDay = 24.0 * 3600
private let twoDays = 48.0 * 3600
private let oneWeek = 24.0 * 7 * 3600

private let dateFormatterWithinLastDay = DateFormatterWithinLastDay()
private let dateFormatterWithinLastWeek = DateFormatterWithinLastWeek()
private let dateFormatterMoreThanAWeek = DateFormatterMoreThanAWeek()

struct EmailListView: View {
  @StateObject var model = MailController.shared.model
  @Binding var selectedTab: Int
  @State var selectedRow:Int32? = 0
  
  private var selectedTabKey: String {
    Tabs[selectedTab]
  }
  
  var body: some View {
    ScrollView {
      LazyVStack {
        let emails = model.sortedEmails[selectedTabKey] ?? []
        ForEach(emails, id: \.uuid) { email in
          let row = getListRow(email)
          if email.seen {
            row
          } else {
            row
              .overlay(RainbowGlowBorder().opacity(0.98))
              .background(VisualEffectBlur(blurStyle: .prominent))
              .cornerRadius(12)
          }
        }
        .onDelete { _ in print("deleted") }
      }
      .padding(.horizontal, 6)
      
      Spacer().frame(height: 138)
    }
    .padding(.horizontal, -2)
  }
  
  private func getListRow(_ email: Email) -> some View {
    let header = email.header!
    let from = header.from
    let sender = header.sender
    let fromLine = from?.displayName ?? sender?.displayName ?? from?.address ?? sender?.address ?? "Unknown"
    let subject = header.subject ?? "None"
    
    return ZStack {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .lastTextBaseline) {
          Text(fromLine)
            .font(.system(size: 15, weight: .bold, design: .default))
            .lineLimit(1)
          Spacer()
          Text(formattedDateFor(header))
            .font(.system(size: 12, weight: .light, design: .default))
            .foregroundColor(Color.secondary)
            Image(systemName: "chevron.right")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundColor(.gray)
              .frame(width: 12, height: 12)
              .offset(x: 0, y: 1)
        }
        Text(subject)
          .font(.system(size: 15, weight: .light, design: .default))
          .lineLimit(2)
      }
      .foregroundColor(Color.primary)
      .padding(.horizontal, 6)
      .padding(.vertical, 12)
      
      NavigationLink(
        destination: EmailDetailView(email: email),
        tag: email.uid,
        selection: $selectedRow
      ) {
        EmptyView()
      }
    }
    .listRowInsets(EdgeInsets())
    .padding(.horizontal, 8)
    .contentShape(Rectangle())
    .onTapGesture {
      selectedRow = email.uid
    }
  }
  
  private func formattedDateFor(_ header: EmailHeader) -> String {
    var formatter: DateFormatter
    let date = header.receivedDate
    let timeSinceMessage = date?.distance(to: Date()) ?? Double.infinity
    
    if  timeSinceMessage > oneDay && timeSinceMessage < twoDays   {
      formatter = dateFormatterWithinLastDay
    } else if timeSinceMessage > twoDays && timeSinceMessage < oneWeek {
      formatter = dateFormatterWithinLastWeek
    } else {
      formatter = dateFormatterMoreThanAWeek
    }
    
    return (date != nil) ? formatter.string(from: date!) : ""
  }
  
}

struct EmailListView_Previews: PreviewProvider {
  @State static var selectedTab: Int = 2
  static var previews: some View {
    EmailListView(selectedTab: $selectedTab)
  }
}

private class DateFormatterWithinLastDay: DateFormatter {
  
  override init() {
    super.init()
    dateFormat = "h:mm a"
    doesRelativeDateFormatting = true
    dateStyle = .short
    timeStyle = .short
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

private class DateFormatterWithinLastWeek: DateFormatter {
  
  override init() {
    super.init()
    dateFormat = "E h:mm a"
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

private class DateFormatterMoreThanAWeek: DateFormatter {
  
  override init() {
    super.init()
    dateFormat = "M/d/yy"
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

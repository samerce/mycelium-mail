import Foundation


private let oneDay = 24.0 * 60 * 60
private let twoDays = oneDay * 2
private let oneWeek = oneDay * 7


class EmailDateFormatter: DateFormatter {
  static let withinLastDay = EmailDateFormatter(format: "h:mm a")
  static let withinLastWeek = EmailDateFormatter(format: "E h:mm a")
  static let moreThanAWeek = EmailDateFormatter(format: "M/d/yy • h:mm a")
  static let moreThanAWeekLongStyle = EmailDateFormatter(format: "MMMM d, yyyy, h:mm a")
  
  static func stringForDate(_ date: Date, style: DateFormatter.Style = .short) -> String {
    var formatter: EmailDateFormatter
    let timeSinceMessage = date.distance(to: .now)
    
    if timeSinceMessage <= oneDay {
      formatter = .withinLastDay
    } else if timeSinceMessage > oneDay && timeSinceMessage <= oneWeek {
      formatter = .withinLastWeek
    } else {
      if style == .short {
        formatter = .moreThanAWeek
      } else {
        // defaults to long for all other date styles
        formatter = .moreThanAWeekLongStyle
      }
    }
    
    return formatter.string(from: date)
  }
  
  init(format: String!) {
    super.init()
    dateFormat = format
  }
  
  required
  init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

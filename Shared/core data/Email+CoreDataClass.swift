import Foundation
import CoreData
import MailCore

private let oneDay = 24.0 * 3600
private let twoDays = 48.0 * 3600
private let oneWeek = 24.0 * 7 * 3600

private let dateFormatterWithinLastDay = DateFormatterWithinLastDay()
private let dateFormatterWithinLastWeek = DateFormatterWithinLastWeek()
private let dateFormatterMoreThanAWeek = DateFormatterMoreThanAWeek()

@objc(Email)
public class Email: NSManagedObject {
  
  var seen: Bool {
    flags.contains(.seen)
  }
  
  var from: EmailAddress? { header!.from }
  var sender: EmailAddress? { header!.sender }
  
  var subject: String {
    header!.subject?.replacingOccurrences(of: "\r\n", with: "") ?? "None"
  }
  var fromLine: String {
    from?.displayName ?? sender?.displayName ??
      from?.address ?? sender?.address ?? "Unknown"
  }
  
  var displayDate: String {
    var formatter: DateFormatter
    let date = header!.receivedDate
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
  
  convenience init(
    message: MCOIMAPMessage, html emailAsHtml: String?,
    perspective _perspective: String, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    
    uuid = UUID()
    uid = Int32(message.uid)
    flags = message.flags
    gmailLabels = Set(message.gmailLabels as? [String] ?? [])
    gmailThreadId = Int64(message.gmailThreadID)
    gmailMessageId = Int64(message.gmailMessageID)
    size = Int32(message.size)
    originalFlags = message.originalFlags
    customFlags = Set(message.customFlags as? [String] ?? [])
    modSeqValue = Int64(message.modSeqValue)
    html = emailAsHtml
    perspective = _perspective
    
    header = EmailHeader(header: message.header, context: context)
    header?.email = self
    
    if let part = message.mainPart {
      mimePart = EmailPart(part: part, context: context)
      mimePart?.email = self
    }
  }
  
  func setFlags(_ setFlags: [MCOMessageFlag]) {
    var newFlags = flags
    for flag in setFlags {
      newFlags.insert(flag)
    }
    flags = newFlags
  }
  
  func removeFlags(_ removeFlags: [MCOMessageFlag]) {
    var newFlags = flags
    for flag in removeFlags {
      newFlags.remove(flag)
    }
    flags = newFlags
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


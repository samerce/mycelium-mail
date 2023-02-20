import Foundation
import CoreData
import MailCore

private let oneDay = 24.0 * 60 * 60
private let twoDays = oneDay * 2
private let oneWeek = oneDay * 7

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
  
  var displayDate: String? {
    if let date = date {
      var formatter: DateFormatter
      let timeSinceMessage = date.distance(to: Date())
      
      if timeSinceMessage <= oneDay {
        formatter = dateFormatterWithinLastDay
      } else if timeSinceMessage > oneDay && timeSinceMessage <= oneWeek {
        formatter = dateFormatterWithinLastWeek
      } else {
        formatter = dateFormatterMoreThanAWeek
      }
      
      return formatter.string(from: date)
    }
    return nil
  }
  
  var longDisplayDate: String? {
    if let date = date {
      var formatter: DateFormatter
      let timeSinceMessage = date.distance(to: Date())
      
      if  timeSinceMessage > oneDay && timeSinceMessage < twoDays   {
        formatter = dateFormatterWithinLastDay
      } else if timeSinceMessage > twoDays && timeSinceMessage < oneWeek {
        formatter = dateFormatterWithinLastWeek
      } else {
        formatter = dateFormatterMoreThanAWeek
        formatter.dateFormat = "MMMM d, yyyy, h:mm a"
      }
      
      return formatter.string(from: date)
    }
    return nil
  }
  
  convenience init(
    message: MCOIMAPMessage, html emailAsHtml: String?,
    bundle: String, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.populate(message: message, html: html, bundle: bundle, context: context)
  }
  
  func populate(message: MCOIMAPMessage, html emailAsHtml: String?,
                bundle _perspective: String, context: NSManagedObjectContext) {
    populate(message: message, html: emailAsHtml, bundle: _perspective)
    
    header = EmailHeader(header: message.header, context: context)
    header?.email = self
    
    if let part = message.mainPart {
      mimePart = EmailPart(part: part, context: context)
      mimePart?.email = self
    }
    
//    thread = fetchOrMakeThread(id: message.gmailThreadID, context: context)
//    thread?.addToEmails(self)
  }
  
  func populate(message: MCOIMAPMessage, html emailAsHtml: String?, bundle _perspective: String) {
    uid = Int32(message.uid)
    flags = message.flags
    gmailLabels = Set(message.gmailLabels as? [String] ?? [])
    gmailMessageId = Int64(message.gmailMessageID)
    size = Int32(message.size)
    originalFlags = message.originalFlags
    customFlags = Set(message.customFlags as? [String] ?? [])
    modSeqValue = Int64(message.modSeqValue)
    html = emailAsHtml
    perspective = _perspective
  }
  
  private var flags: MCOMessageFlag {
    get {
      MCOMessageFlag(rawValue: Int(flagsRaw))
    }
    set {
      flagsRaw = Int16(newValue.rawValue)
    }
  }
  
  private(set) var originalFlags: MCOMessageFlag {
    get {
      MCOMessageFlag(rawValue: Int(originalFlagsRaw))
    }
    set {
      originalFlagsRaw = Int16(newValue.rawValue)
    }
  }
  
  func addFlags(_ _flags: MCOMessageFlag) {
    var newFlags = flags
    newFlags.insert(_flags)
    flags = newFlags
  }
  
  func removeFlags(_ _flags: MCOMessageFlag) {
    var newFlags = flags
    newFlags.remove(_flags)
    flags = newFlags
  }
  
  private func fetchOrMakeThread(id: UInt64, context: NSManagedObjectContext) -> EmailThread? {
    do {
      if id > Int64.max {
        print("error: tried to make or fetch a thread with an id greater than Int64.max, skpping. fix this!")
        return nil
      }
      
      let threadFetchRequest: NSFetchRequest<EmailThread> = EmailThread.fetchRequest()
      threadFetchRequest.predicate = NSPredicate(format: "id == %@", Int64(id))
      
      let threads = try context.fetch(threadFetchRequest) as [EmailThread]
      if !threads.isEmpty {
        return threads.first
      } else {
        return EmailThread(id: Int64(id), context: context)
      }
    }
    catch let error {
      print("error fetching thread: \(error.localizedDescription)")
    }
    
    print("warning: failed to create EmailThread, returning nil")
    return nil
  }
  
}

private class DateFormatterWithinLastDay: DateFormatter {
  
  override init() {
    super.init()
    dateFormat = "h:mm a"
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
    dateFormat = "M/d/yy • h:mm a"
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}


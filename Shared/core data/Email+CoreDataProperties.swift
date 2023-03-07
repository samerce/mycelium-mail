import Foundation
import CoreData


extension Email {
  
  var moc: NSManagedObjectContext? { managedObjectContext }
  
  var subject: String {
    subjectRaw.replacingOccurrences(of: "\r\n", with: "")
  }
  
  var fromLine: String {
    from.displayName ?? sender?.displayName ?? from.address
  }
  
  var toLine: String {
    guard let to = to
    else { return "Unknown" }
    
    return to.map { $0.displayName ?? $0.address }
      .joined(separator: ", ")
  }
  
  var displayDate: String? {
    return EmailDateFormatter.stringForDate(receivedDate)
  }
  
  var longDisplayDate: String? {
    return EmailDateFormatter.stringForDate(receivedDate)
  }
  
  var bundles: [EmailBundle] {
    (bundleSet.allObjects as? [EmailBundle]) ?? []
  }
  
  var from: EmailAddress {
    get {
      return (try? JSONDecoder().decode(EmailAddress.self, from: Data(fromJSON.utf8)))
      ?? EmailAddress(address: "unknown")
    }
    set {
      do {
        let json = try JSONEncoder().encode(newValue)
        fromJSON = String(data: json, encoding:.utf8)!
      } catch {
        fromJSON = ""
      }
    }
  }
  
  var sender: EmailAddress? {
    get {
      return (try? JSONDecoder().decode(EmailAddress.self, from: Data(senderJSON.utf8))) ?? nil
    }
    set {
      do {
        let json = try JSONEncoder().encode(newValue)
        senderJSON = String(data: json, encoding:.utf8)!
      } catch {
        senderJSON = ""
      }
    }
  }
  
  var bcc: [EmailAddress]? {
    get {
      return (try? JSONDecoder().decode([EmailAddress].self, from: Data(bccJSON.utf8))) ?? nil
    }
    set {
      do {
        let json = try JSONEncoder().encode(newValue)
        bccJSON = String(data: json, encoding:.utf8)!
      } catch {
        bccJSON = ""
      }
    }
  }
  
  var cc: [EmailAddress]? {
    get {
      return (try? JSONDecoder().decode([EmailAddress].self, from: Data(ccJSON.utf8))) ?? nil
    }
    set {
      do {
        let json = try JSONEncoder().encode(newValue)
        ccJSON = String(data: json, encoding:.utf8)!
      } catch {
        ccJSON = ""
      }
    }
  }
  
  var replyTo: [EmailAddress]? {
    get {
      return (try? JSONDecoder().decode([EmailAddress].self, from: Data(replyToJSON.utf8))) ?? nil
    }
    set {
      do {
        let json = try JSONEncoder().encode(newValue)
        replyToJSON = String(data: json, encoding:.utf8)!
      } catch {
        replyToJSON = ""
      }
    }
  }
  
  var to: [EmailAddress]? {
    get {
      return (try? JSONDecoder().decode([EmailAddress].self, from: Data(toJSON.utf8))) ?? nil
    }
    set {
      do {
        let json = try JSONEncoder().encode(newValue)
        toJSON = String(data: json, encoding:.utf8)!
      } catch {
        toJSON = ""
      }
    }
  }
  
  @NSManaged public var customFlags: Set<String>
  @NSManaged public var flagsRaw: Int16
  @NSManaged public var gmailLabels: Set<String>
  @NSManaged public var gmailMessageId: Int64
  @NSManaged public var gmailThreadId: Int64
  @NSManaged public var html: String
  @NSManaged public var modSeqValue: Int64 // last mod seq on server, see RFC4551
  @NSManaged public var originalFlagsRaw: Int16 // flags when first fetched
  @NSManaged public var size: Int32
  @NSManaged public var uid: Int32 // imap id
  @NSManaged public var trashed: Bool
  @NSManaged public var isLatestInThread: Bool
  @NSManaged public var inReplyTo: Set<String> // message ids
  @NSManaged public var receivedDate: Date
  @NSManaged public var sentDate: Date
  @NSManaged public var subjectRaw: String
  @NSManaged public var userAgent: String? // x-mailer header
  @NSManaged public var references: Set<String> // message ids
  
  @NSManaged public var fromJSON: String // EmailAddress
  @NSManaged public var senderJSON: String // EmailAddress
  @NSManaged public var bccJSON: String // [EmailAddress]
  @NSManaged public var ccJSON: String // [EmailAddress]
  @NSManaged public var replyToJSON: String // [EmailAddress]
  @NSManaged public var toJSON: String // [EmailAddress]
  
  @NSManaged public var account: Account
  @NSManaged public var mimePart: EmailPart?
  @NSManaged public var thread: EmailThread?
  @NSManaged public var bundleSet: NSSet // <EmailBundle>
  
}

// MARK: - Generated accessors for emails

extension Email {
  
  @objc(addBundleSetObject:)
  @NSManaged public func addToBundleSet(_ value: EmailBundle)
  
  @objc(removeBundleSetObject:)
  @NSManaged public func removeFromBundleSet(_ value: EmailBundle)
  
  @objc(addBundleSet:)
  @NSManaged public func addToBundleSet(_ values: NSSet)
  
  @objc(removeBundleSet:)
  @NSManaged public func removeFromBundleSet(_ values: NSSet)
  
}


extension Email : Identifiable {
  
}

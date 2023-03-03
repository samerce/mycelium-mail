import Foundation
import CoreData


extension Email {
  
  var from: EmailAddress? { header!.from }
  var sender: EmailAddress? { header!.sender }
  var to: EmailAddress? { header!.to?.allObjects.first as? EmailAddress }
  
  var subject: String {
    header!.subject?.replacingOccurrences(of: "\r\n", with: "") ?? "None"
  }
  
  var fromLine: String {
    from?.displayName ?? sender?.displayName ??
      from?.address ?? sender?.address ?? "Unknown"
  }
  
  var toLine: String {
    to?.displayName ?? to?.address ?? "Unknown"
  }
  
  var displayDate: String? {
    guard let date = date
    else { return nil }
    return EmailDateFormatter.stringForDate(date)
  }
  
  var longDisplayDate: String? {
    guard let date = date
    else { return nil }
    return EmailDateFormatter.stringForDate(date)
  }
  
  var bundles: [EmailBundle] {
    (bundleSet.allObjects as? [EmailBundle]) ?? []
  }
  
  @NSManaged public var customFlags: Set<String>
  @NSManaged public var date: Date?
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

  @NSManaged public var bundleSet: NSSet
  @NSManaged public var account: Account?
  @NSManaged public var header: EmailHeader?
  @NSManaged public var mimePart: EmailPart?
  @NSManaged public var thread: EmailThread?
  
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

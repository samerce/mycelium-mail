import Foundation
import CoreData
import MailCore

private let byDateDescending = NSSortDescriptor(key: "date", ascending: false)

extension Email {
  
  @nonobjc public class
  func fetchRequest() -> NSFetchRequest<Email> {
    return NSFetchRequest<Email>(entityName: "Email")
  }
  
  @nonobjc public class
  func emptyFetchRequest() -> NSFetchRequest<Email> {
    let request = Email.fetchRequest()
    request.sortDescriptors = []
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    request.predicate = NSPredicate(format: "SELF == %@", "zero")
    return request
  }
  
  @nonobjc public class
  func fetchRequestForEmailWithId(_ id: NSManagedObjectID? = nil) -> NSFetchRequest<Email> {
    let request = Email.fetchRequest()
    request.sortDescriptors = []
    request.predicate = id == nil ? nil : NSPredicate(format: "SELF == %@", id!)
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    return request
  }
  
  @nonobjc public class
  func fetchRequestForBundle(_ bundle: EmailBundle?) -> NSFetchRequest<Email> {
    let fetchRequest = Email.fetchRequest()
    fetchRequest.sortDescriptors = [byDateDescending]
    fetchRequest.predicate = predicateForBundle(bundle)
    fetchRequest.fetchBatchSize = 108
//    fetchRequest.fetchLimit = 108
    fetchRequest.propertiesToFetch = ["date"]
    fetchRequest.relationshipKeyPathsForPrefetching = ["header"]
    return fetchRequest
  }
  
  @nonobjc public class
  func predicateForBundle(_ bundle: EmailBundle?) -> NSPredicate? {
    if let bundle = bundle {
      return NSPredicate(format: "ANY bundleSet.name == %@ AND trashed != TRUE", bundle.name)
    }
    return nil
  }
  
  @NSManaged public var customFlags: Set<String>
  @NSManaged public var date: Date?
  @NSManaged public var flagsRaw: Int16
  @NSManaged public var gmailLabels: Set<String>
  @NSManaged public var gmailMessageId: Int64
  @NSManaged public var gmailThreadId: Int64
  @NSManaged public var html: String?
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

// MARK: Generated accessors for emails
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

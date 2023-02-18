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
  func fetchRequestForBundle(_ bundle: String = "", _ offset: Int = 0) -> NSFetchRequest<Email> {
    let fetchRequest = NSFetchRequest<Email>(entityName: "Email")
    fetchRequest.sortDescriptors = [byDateDescending]
    fetchRequest.shouldRefreshRefetchedObjects = true
    fetchRequest.fetchBatchSize = 54
    fetchRequest.fetchOffset = offset
    fetchRequest.fetchLimit = 1080
    
    if !bundle.isEmpty && bundle != "everything" {
      fetchRequest.predicate = NSPredicate(format: "perspective == %@", bundle)
    }
    
    return fetchRequest
  }
  
  @NSManaged public var customFlags: Set<String>?
  @NSManaged public var date: Date?
  @NSManaged public var flagsRaw: Int16
  @NSManaged public var gmailLabels: Set<String>?
  @NSManaged public var gmailMessageId: Int64
  @NSManaged public var gmailThreadId: Int64
  @NSManaged public var html: String?
  @NSManaged public var modSeqValue: Int64 // last mod seq on server, see RFC4551
  @NSManaged public var originalFlagsRaw: Int16 // flags when first fetched
  @NSManaged public var perspective: String? // aka ai category
  @NSManaged public var size: Int32
  @NSManaged public var uid: Int32 // imap id

  @NSManaged public var account: Account?
  @NSManaged public var header: EmailHeader?
  @NSManaged public var mimePart: EmailPart?
  @NSManaged public var thread: EmailThread?
  
}

extension Email : Identifiable {
  
}

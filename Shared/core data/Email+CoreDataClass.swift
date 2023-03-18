import Foundation
import CoreData


@objc(Email)
public class Email: NSManagedObject {
  
  // MARK: - FETCHING
  
  @nonobjc public class
  func fetchRequest() -> NSFetchRequest<Email> {
    let request = NSFetchRequest<Email>(entityName: "Email")
    request.sortDescriptors = []
    return request
  }
  
  @nonobjc public class
  func emptyFetchRequest() -> NSFetchRequest<Email> {
    let request = Email.fetchRequest()
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    request.predicate = NSPredicate(format: "FALSEPREDICATE")
    return request
  }
  
  @nonobjc public class
  func fetchRequestForEmailWithId(_ id: NSManagedObjectID? = nil) -> NSFetchRequest<Email> {
    let request = Email.fetchRequest()
    request.predicate = id == nil ? nil : NSPredicate(format: "SELF == %@", id!)
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    return request
  }
  
  @nonobjc public class
  func fetchRequestForBundle(_ bundle: EmailBundle?) -> NSFetchRequest<Email> {
    let fetchRequest = Email.fetchRequest()
    fetchRequest.sortDescriptors = [.byDateDescending]
    fetchRequest.predicate = predicateForBundle(bundle)
    fetchRequest.fetchBatchSize = 108
    fetchRequest.fetchLimit = 216 // TODO: why does app hang without this?
//    fetchRequest.propertiesToFetch = ["date"]
//    fetchRequest.relationshipKeyPathsForPrefetching = ["header", "account"]
    return fetchRequest
  }
  
  @nonobjc public class
  func fetchRequestWithProps(_ props: Any...) -> NSFetchRequest<Email> {
    let request = Email.fetchRequest()
    request.propertiesToFetch = props
    return request
  }
  
  @nonobjc public class
  func predicateForBundle(_ bundle: EmailBundle?) -> NSPredicate? {
    guard let bundle = bundle
    else { return nil }
    
    return NSPredicate(
      format: "ANY bundleSet.name == %@ AND trashed != TRUE AND isLatestInThread == TRUE",
      bundle.name
    )
  }
  
  
  // MARK: - HELPERS
  
//  func addThread(id: UInt64, context: NSManagedObjectContext) throws {
//    if id > Int64.max {
//      throw PsyError.unexpectedError(
//        message: "error: tried to make or fetch a thread with an id greater than Int64.max, skpping. fix this!"
//      )
//    }
//    
//    let threadFetchRequest = EmailThread.fetchRequest()
//    threadFetchRequest.predicate = NSPredicate(format: "id == %d", id)
//    threadFetchRequest.fetchLimit = 1
//    threadFetchRequest.fetchBatchSize = 1
//    
//    let threads = try context.fetch(threadFetchRequest) as [EmailThread]
//    thread = threads.first ?? EmailThread(id: Int64(id), context: context)
//    thread!.addToEmails(self)
//    
//    // the following assumes emails are always added in chronological order
//    for email in thread!.emails.allObjects as! [Email] {
//      email.isLatestInThread = false
//    }
//    self.isLatestInThread = true
//  }
  
}


extension NSSortDescriptor {
  static let byThreadIdDescending = NSSortDescriptor(key: "threadId", ascending: false)
  static let byDateDescending = NSSortDescriptor(key: "receivedDate", ascending: false)
  static let byLastMessageDateDescending = NSSortDescriptor(key: "lastMessageDate", ascending: false)
}

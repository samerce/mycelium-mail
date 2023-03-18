import Foundation
import CoreData


@objc(EmailThread)
public class EmailThread: NSManagedObject {
  
  @nonobjc public class
  func fetchRequest(id: Int64? = nil) -> NSFetchRequest<EmailThread> {
    let request = NSFetchRequest<EmailThread>(entityName: "EmailThread")
    if let id = id {
      request.predicate = NSPredicate(format: "id == %d", id)
    }
    return request
  }
  
  @nonobjc public class
  func fetchRequestForBundle(_ bundle: EmailBundle?) -> NSFetchRequest<EmailThread> {
    let fetchRequest = EmailThread.fetchRequest()
    fetchRequest.sortDescriptors = [.byLastMessageDateDescending]
    fetchRequest.predicate = predicateForBundle(bundle)
    fetchRequest.fetchBatchSize = 108
    fetchRequest.fetchLimit = 216 // TODO: why does app hang without this?
//    fetchRequest.propertiesToFetch = ["date"]
//    fetchRequest.relationshipKeyPathsForPrefetching = ["header", "account"]
    return fetchRequest
  }
  
  @nonobjc public class
  func predicateForBundle(_ bundle: EmailBundle?) -> NSPredicate? {
    guard let bundle = bundle
    else { return nil }
    
    return NSPredicate(
      format: "bundle.name == %@ AND trashed == FALSE",
      bundle.name
    )
  }
  
  // MARK: - INIT
  
//  convenience init(id: Int64, context: NSManagedObjectContext) {
//    self.init(context: context)
//    self.id = id
//    self.emails = NSSet()
//    self.trashed = false
//  }
  
}

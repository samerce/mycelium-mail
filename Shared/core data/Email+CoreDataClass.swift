import Foundation
import CoreData


private let byDateDescending = NSSortDescriptor(key: "date", ascending: false)


@objc(Email)
public class Email: NSManagedObject {
  
  // MARK: - FETCHES
  
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
    fetchRequest.sortDescriptors = [byDateDescending]
    fetchRequest.predicate = predicateForBundle(bundle)
    fetchRequest.fetchBatchSize = 108
    fetchRequest.fetchLimit = 216 // TODO: why does app hang without this?
//    fetchRequest.propertiesToFetch = ["date"]
//    fetchRequest.relationshipKeyPathsForPrefetching = ["header", "account"]
    return fetchRequest
  }
  
  @nonobjc public class
  func predicateForBundle(_ bundle: EmailBundle?) -> NSPredicate? {
    if let bundle = bundle {
      return NSPredicate(format: "ANY bundleSet.name == %@ AND trashed != TRUE", bundle.name)
    }
    return nil
  }
  
  
  // MARK: - HELPERS
  
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

import Foundation
import CoreData


@objc(EmailThread)
public class EmailThread: NSManagedObject {
  
  // MARK: - FETCHING
  
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
  
  // MARK: - MANIPULATION
  
  /// MailController should be the only one that calls this
  func moveToBundle(_ toBundle: EmailBundle, fromBundle: EmailBundle, always: Bool = true) async throws {
    try await managedObjectContext?.perform {
      self.bundle = toBundle
      fromBundle.removeFromThreadSet(self)
      toBundle.addToThreadSet(self)
      try self.managedObjectContext?.save() // optimistically update the ui
    }
    
    if toBundle.name == "inbox" {
      try await self.removeLabels(["psymail/\(fromBundle.name)"])
      try await self.deleteFilterForBundle(fromBundle)
      return
    }
    
    try await self.addLabels(["psymail/\(toBundle.name)"])
    try await self.removeLabels([cInboxLabel])
    
    if always {
      try await self.filterIntoBundle(toBundle)
    }
  }
  
}

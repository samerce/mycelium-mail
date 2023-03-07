import Foundation
import CoreData

@objc(EmailBundle)
public class EmailBundle: NSManagedObject {
  
  // MARK: - FETCHING
  
  @nonobjc public class
  func fetchRequest() -> NSFetchRequest<EmailBundle> {
    let request = NSFetchRequest<EmailBundle>(entityName: "EmailBundle")
    request.sortDescriptors = []
    return request
  }
  
  @nonobjc public class
  func fetchRequestWithProps(_ props: Any...) -> NSFetchRequest<EmailBundle> {
    let request = EmailBundle.fetchRequest()
    request.propertiesToFetch = props
    return request
  }
  
  @nonobjc public class
  func fetchRequestWithName(_ name: String) -> NSFetchRequest<EmailBundle> {
    let request = EmailBundle.fetchRequest()
    request.predicate = NSPredicate(format: "name == %@", name)
    request.fetchBatchSize = 1
    request.fetchLimit = 1
    return request
  }
  
  // MARK: - INIT
  
  convenience init(
    name: String, gmailLabelId: String, icon: String = "", orderIndex: Int, context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.name = name
    self.gmailLabelId = gmailLabelId
    self.icon = icon
    self.orderIndex = Int16(orderIndex)
    self.lastSeenDate = .now
    self.newEmailsSinceLastSeen = 0
  }
  
  // MARK: - PUBLIC
  
  public func onSelected() {
    lastSeenDate = .now
    newEmailsSinceLastSeen = 0
  }
  
}

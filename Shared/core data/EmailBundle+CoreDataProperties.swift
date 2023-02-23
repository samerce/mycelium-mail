import Foundation
import CoreData


extension EmailBundle {
  
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
  
  @NSManaged public var name: String
  @NSManaged public var icon: String
  @NSManaged public var gmailLabelId: String
  @NSManaged public var emailSet: NSSet
  
  var emails: [Email] {
    (emailSet.allObjects as? [Email]) ?? []
  }
  
}


// MARK: - Generated accessors for emails

extension EmailBundle {
  
  @objc(addEmailSetObject:)
  @NSManaged public func addToEmailSet(_ value: Email)
  
  @objc(removeEmailSetObject:)
  @NSManaged public func removeFromEmailSet(_ value: Email)
  
  @objc(addEmailSet:)
  @NSManaged public func addToEmailSet(_ values: NSSet)
  
  @objc(removeEmailSet:)
  @NSManaged public func removeFromEmailSet(_ values: NSSet)
  
}

extension EmailBundle : Identifiable {
  
}

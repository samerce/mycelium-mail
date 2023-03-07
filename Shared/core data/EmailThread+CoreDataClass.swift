import Foundation
import CoreData

@objc(EmailThread)
public class EmailThread: NSManagedObject {
  
  convenience init(id: Int64, context: NSManagedObjectContext) {
    self.init(context: context)
    self.id = id
    self.emails = NSSet()
  }
  
}

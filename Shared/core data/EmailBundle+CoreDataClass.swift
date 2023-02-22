import Foundation
import CoreData

@objc(EmailBundle)
public class EmailBundle: NSManagedObject {
  
  convenience init(
    name: String, gmailLabelId: String, icon: String = "", context: NSManagedObjectContext
  ) {
    self.init(context: context)
    self.name = name
    self.gmailLabelId = gmailLabelId
    self.icon = icon
  }
  
}

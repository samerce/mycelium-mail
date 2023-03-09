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
    name: String, labelId: String, icon: String? = nil, orderIndex: Int, context: NSManagedObjectContext
  ) {
    // TODO: get rid of this config for prod
    let config = cBundleConfigByName[name]
    let index = cBundleConfig.firstIndex(where: { $0["name"] == name }) ?? orderIndex
    
    self.init(context: context)
    self.name = name
    self.labelId = labelId
    self.icon = icon ?? config?["icon"] ?? "questionmark.square"
    self.orderIndex = Int16(index)
    self.lastSeenDate = .now
    self.newEmailsSinceLastSeen = 0
  }
  
  // MARK: - PUBLIC
  
  public func onSelected() {
    lastSeenDate = .now
    newEmailsSinceLastSeen = 0
  }
  
}


// TODO: get rid of this
private let cBundleConfig = [
  [
    "name": "notifications",
    "icon": "bell"
  ],
  [
    "name": "updates",
    "icon": "livephoto"
  ],
  [
    "name": "inbox",
    "icon": "tray.full"
  ],
  [
    "name": "newsletters",
    "icon": "newspaper"
  ],
  [
    "name": "events",
    "icon": "calendar"
  ],
  [
    "name": "health",
    "icon": "heart.text.square"
  ],
  [
    "name": "commerce",
    "icon": "creditcard"
  ],
  [
    "name": "jobs",
    "icon": "briefcase",
  ],
  [
    "name": "classifieds",
    "icon": "scalemass"
  ],
  [
    "name": "travel",
    "icon": "backpack"
  ],
  [
    "name": "society",
    "icon": "building.2"
  ],
  [
    "name": "marketing",
    "icon": "megaphone"
  ]
]
private let cBundleConfigByName = cBundleConfig.reduce(into: [:], { result, config in
  result[config["name"]] = config
})

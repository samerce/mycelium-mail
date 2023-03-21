import Foundation

extension Account {
  
  func createLabel(_ name: String) async throws -> GLabel {
    let (labelListResponse, _) = try await Gmail.call(.listLabels, forAccount: self)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    if let label = labels.first(where: { $0.name == name }) {
      print("label exists, skipping creation")
      return label
    }
    
    let (label, _) = try await Gmail.call(.createLabel, forAccount: self, withBody: [
      "name": name,
      "labelListVisibility": "labelShow",
      "messageListVisibility": "show",
      "type": "user"
    ])
    return (label as! GLabel)
  }
  
  func syncBundles() async throws {
    guard let context = moc
    else {
      throw PsyError.unexpectedError(message: "no moc to sync bundles")
    }
    
    let bundleFetchRequest = EmailBundle.fetchRequestWithProps("name", "labelId")
    let bundles = try context.fetch(bundleFetchRequest)
    
    let (labelListResponse, _) = try await Gmail.call(.listLabels, forAccount: self)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    // TODO: use batch insert?
    for label in labels {
      if !label.name.contains("psymail/") {
        continue
      }
      
      let bundleName = label.name.replacing("psymail/", with: "")
      let bundle = bundles.first(where: { $0.name == bundleName }) ?? EmailBundle(name: bundleName,
                                                                                  labelId: label.id,
                                                                                  orderIndex: bundles.count,
                                                                                  context: context)
      
      // TODO: update this to work with multiple accounts
      bundle.labelId = label.id
    }
    
    if context.hasChanges { try context.save() }
  }
  
}

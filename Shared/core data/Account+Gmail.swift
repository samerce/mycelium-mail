import Foundation

extension Account {
  
  func createLabel(_ name: String) async throws -> GLabel {
    let (labelListResponse, _) = try await GmailEndpoint.call(.listLabels, forAccount: self)
    let labels = (labelListResponse as! GLabelListResponse).labels
    
    if let label = labels.first(where: { $0.name == name }) {
      print("label exists, skipping creation")
      return label
    }
    
    let (label, _) = try await GmailEndpoint.call(.createLabel, forAccount: self, withBody: [
      "name": name,
      "labelListVisibility": "labelShow",
      "messageListVisibility": "show",
      "type": "user"
    ])
    return (label as! GLabel)
  }
  
}

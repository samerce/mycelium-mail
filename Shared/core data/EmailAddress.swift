import Foundation


public struct EmailAddress: Codable, Hashable {
  public var address: String
  public var displayName: String?
}

import Foundation
import MailCore


extension EmailAddress {
  
  init(address: MCOAddress) {
    self.init(address: address.mailbox, displayName: address.displayName)
  }
  
}

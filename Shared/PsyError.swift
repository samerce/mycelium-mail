import Foundation

enum PsyError: Error {
  case wrongDataFormat(_ error: Error)
  case emailAlreadyExists
//  case missingData
  case creationError
  case failedToCreateOperation(_ error: Error? = nil, message: String? = "")
  case batchInsertError
  case batchDeleteError
  case persistentHistoryChangeError
  case gmailCallFailed(_ error: Error? = nil, message: String? = "")
  case labelUpdateFailed(_ error: Error? = nil, message: String? = "")
  case unexpectedError(_ error: Error? = nil, message: String? = "")
}

extension PsyError: LocalizedError {
  var errorDescription: String? {
    switch self {
      case .wrongDataFormat(let error):
        return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
      
      case .emailAlreadyExists:
        return NSLocalizedString("tried to add email already stored in core data", comment: "")
      
//      case .missingData:
//        return NSLocalizedString("Found and will discard a quake missing a valid code, magnitude, place, or time.", comment: "")
        
      case .failedToCreateOperation(let error, let  message):
        return errorMessage(error, "failed to create MailCore operation.\n\(message ?? "")")
      
      case .creationError:
        return NSLocalizedString("Failed to create a new Quake object.", comment: "")
      
      case .batchInsertError:
        return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
      
      case .batchDeleteError:
        return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
      
      case .persistentHistoryChangeError:
        return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
      
      case .gmailCallFailed(let error, let message):
        return errorMessage(error, "gmail call failed: \(message ?? "")")
      
      case .labelUpdateFailed(let error, let message):
        return errorMessage(error, "updating gmail labels failed: \(message ?? "")")
      
      case .unexpectedError(let error, let message):
        return errorMessage(error, "unexpected error: \(message ?? "")")
    }
  }
  
  private func errorMessage(_ error: Error? = nil, _ message: String? = "") -> String {
    return NSLocalizedString("\(message ?? ""): \(error?.localizedDescription ?? "")", comment: "")
  }
}

extension PsyError: Identifiable {
  var id: String? { errorDescription }
}

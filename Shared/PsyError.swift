import Foundation

enum PsyError: Error {
  case wrongDataFormat(error: Error)
  case emailAlreadyExists
  case missingData
  case creationError
  case batchInsertError
  case batchDeleteError
  case persistentHistoryChangeError
  case unexpectedError(error: Error)
}

extension PsyError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .wrongDataFormat(let error):
      return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
    case .emailAlreadyExists:
      return NSLocalizedString("tried to add email already stored in core data", comment: "")
    case .missingData:
      return NSLocalizedString("Found and will discard a quake missing a valid code, magnitude, place, or time.", comment: "")
    case .creationError:
      return NSLocalizedString("Failed to create a new Quake object.", comment: "")
    case .batchInsertError:
      return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
    case .batchDeleteError:
      return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
    case .persistentHistoryChangeError:
      return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
    case .unexpectedError(let error):
      return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
    }
  }
}

extension PsyError: Identifiable {
  var id: String? { errorDescription }
}

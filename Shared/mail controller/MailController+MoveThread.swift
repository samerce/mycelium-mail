import Foundation
import CoreData


private let dataCtrl = PersistenceController.shared
private let taskCtrl = TaskController.shared
private let alertCtrl = AppAlertController.shared


extension MailController {
  
  func moveThread(
    _ thread: EmailThread, toBundleNamed toBundleName: String, fromBundle: EmailBundle? = nil, always: Bool = true
  ) {
    Task {
      let toBundle = try await dataCtrl.context.perform {
        return try EmailBundle.fetchRequestWithName(toBundleName).execute().first
      }
      
      guard let toBundle = toBundle
      else {
        throw PsyError.unexpectedError(message: "couldn't find bundle named \(toBundleName) for move operation")
      }
      
      self.moveThread(thread, toBundle: toBundle, fromBundle: fromBundle, always: always)
    }
  }
  
  func moveThread(
    _ thread: EmailThread, toBundle: EmailBundle, fromBundle: EmailBundle? = nil, always: Bool = true
  ) {
    let _fromBundle = fromBundle ?? thread.bundle
    
    Task {
      do {
        try await taskCtrl.run(PsyTask {
          try await thread.moveToBundle(toBundle, fromBundle: _fromBundle, always: always)
          dataCtrl.save()
        } undo: {
          try await thread.moveToBundle(_fromBundle, fromBundle: toBundle, always: always)
          dataCtrl.save()
        })
      } catch {
        alertCtrl.show(message: "failed to move message", icon: "xmark", delay: 1)
        print("failed to move message\n\(thread.subject)\nto bundle \(toBundle.name) from bundle \(_fromBundle.name)\nerror: \(error.localizedDescription)")
      }
    }
  }
}

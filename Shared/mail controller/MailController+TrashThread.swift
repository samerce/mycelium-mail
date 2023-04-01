import Foundation
import CoreData


private let dataCtrl = PersistenceController.shared
private let taskCtrl = TaskController.shared
private let alertCtrl = AppAlertController.shared


extension MailController {
  
  func trashThread(_ thread: EmailThread) {
    Task {
      do {
        try await taskCtrl.run(PsyTask {
          try await thread.moveToTrash()
          dataCtrl.save()
        } undo: {
          try await thread.restoreFromTrash()
          dataCtrl.save()
        })
      } catch {
        alertCtrl.show(message: "failed to trash message", icon: "xmark", delay: 1)
        print("failed to trash message\n\(thread.subject)\nerror: \(error.localizedDescription)")
      }
    }
  }
  
}

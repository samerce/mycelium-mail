import Foundation
import CoreData


private let dataCtrl = PersistenceController.shared
private let taskCtrl = TaskController.shared
private let alertCtrl = AppAlertController.shared


extension MailController {
  
  func markThread(_ thread: EmailThread, seen: Bool = true) {
    Task {
      do {
        try await taskCtrl.run(PsyTask {
          try await thread.markSeen(seen)
          dataCtrl.save()
        } undo: {
          try await thread.markSeen(!seen)
          dataCtrl.save()
        })
      } catch {
        alertCtrl.show(message: "failed to toggle unread status", icon: "xmark", delay: 1)
        print("failed to toggle seen status: \(error.localizedDescription)")
      }
    }
  }
  
  func markThread(_ thread: EmailThread, flagged: Bool = true) {
    Task {
      do {
        try await taskCtrl.run(PsyTask {
          try await thread.markFlagged(flagged)
          dataCtrl.save()
        } undo: {
          try await thread.markFlagged(!flagged)
          dataCtrl.save()
        })
      } catch {
        alertCtrl.show(message: "failed to toggle pinned status", icon: "xmark", delay: 1)
        print("failed to toggle flagged status: \(error.localizedDescription)")
      }
    }
  }
  
}

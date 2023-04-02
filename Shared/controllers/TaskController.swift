import Foundation


class TaskController {
  static let shared = TaskController()
  private init() {}
  
  // MARK: -
  
  func run(_ tasks: PsyTask...) async throws {
    var completed = false
    var retries = 0
    
    while !completed && retries <= cNumRetries {
      do {
        try await _run(tasks)
        completed = true
      }
      catch {
        if retries < cNumRetries {
          retries += 1
        } else {
          throw error
        }
      }
    }
  }
  
  private func _run(_ tasks: [PsyTask]) async throws {
    try await withThrowingTaskGroup(of: (Any).self) { taskGroup in
      for task in tasks {
        guard taskGroup.addTaskUnlessCancelled(operation: { try await task.run() })
        else { break }
      }
      
      var numCompletedTasks = 0
      do {
        // pre-increment so that if the next task fails, its undo is called
        numCompletedTasks += 1
        let _ = try await taskGroup.next()
      }
      catch {
        let originalError = error
        for i in 0...numCompletedTasks {
          do {
            try await tasks[i].undo?()
          } catch {
            // TODO: can this be handled better?
            throw PsyError.unexpectedError(
              error,
              message: "failed to undo a task while recovering from \(originalError.localizedDescription)"
            )
          }
        }
        throw error
      }
    }
  }
  
}

// MARK: - DEFINITIONS

typealias TaskBlockAsync = () async throws -> Void
typealias UndoBlockAsync = () async throws -> Void

struct PsyTask {
  var run: TaskBlockAsync
  var undo: UndoBlockAsync?
  var retries = 0
  
  init(_ run: @escaping TaskBlockAsync, undo: UndoBlockAsync? = nil) {
    self.run = run
    self.undo = undo
  }
}

private let cNumRetries = 1

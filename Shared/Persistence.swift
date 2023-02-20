import CoreData
import Combine
import OSLog


private let log = Logger(subsystem: "cum.expressyouryes.psymail", category: "Persistence")

class PersistenceController: ObservableObject {
  // MARK: - STATIC
  
  static let shared = PersistenceController()
  
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    
    do {
      try viewContext.save()
    } catch {
      // Replace this implementation with code to handle the error appropriately.
      // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    return result
  }()
  
  // MARK: - INSTANCE
  
  private let inMemory: Bool
  private var notificationToken: NSObjectProtocol?
  /// A peristent history token used for fetching transactions from the store.
  private var lastToken: NSPersistentHistoryToken?
  
  lazy var container: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "psymail")
    
    guard let description = container.persistentStoreDescriptions.first else {
      fatalError("Failed to retrieve a persistent store description.")
    }
    
    if inMemory {
      description.url = URL(fileURLWithPath: "/dev/null")
    }
    
    description.setOption(true as NSNumber,
                          forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    
    description.setOption(true as NSNumber,
                          forKey: NSPersistentHistoryTrackingKey)
    
    container.loadPersistentStores { storeDescription, error in
      if let error = error as NSError? {
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
    
    container.viewContext.automaticallyMergesChangesFromParent = false
    container.viewContext.name = "viewContext"
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    container.viewContext.shouldDeleteInaccessibleFaults = true
    
    // Set unused undoManager to nil for macOS (nil by default on iOS) to reduce resource requirements.
    container.viewContext.undoManager = nil
    
    return container
  }()
  
  
  init(inMemory: Bool = false) {
    self.inMemory = inMemory
    
    // Observe Core Data remote change notifications on the queue where the changes were made.
//    notificationToken = NotificationCenter.default.addObserver(
//      forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil
//    ) { note in
//      log.debug("Received a persistent store remote change notification.")
//      Task {
//        await self.fetchPersistentHistory()
//      }
//    }
  }
  
  func save() {
    let context = container.viewContext
    
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Show some error here
      }
    }
  }
  
  // MARK: - PRIVATE
  
  /// Creates and configures a private queue context.
  func newTaskContext() -> NSManagedObjectContext {
    let taskContext = container.newBackgroundContext()
    taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    taskContext.undoManager = nil
//    taskContext.automaticallyMergesChangesFromParent = true
    return taskContext
  }
  
  func fetchPersistentHistory() async {
    do {
      try await fetchPersistentHistoryTransactionsAndChanges()
    } catch {
      log.debug("\(error.localizedDescription)")
    }
  }
  
  private func fetchPersistentHistoryTransactionsAndChanges() async throws {
    let taskContext = newTaskContext()
    taskContext.name = "persistentHistoryContext"
    log.debug("Start fetching persistent history changes from the store...")
    
    try await taskContext.perform {
      // Execute the persistent history change since the last transaction.
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
      let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
      if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
         !history.isEmpty {
        self.mergePersistentHistoryChanges(from: history)
        return
      }
      
      log.debug("No persistent history transactions found.")
      throw PsyError.persistentHistoryChangeError
    }
    
    log.debug("Finished merging history changes.")
  }
  
  private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
    log.debug("Received \(history.count) persistent history transactions.")
    // Update view context with objectIDs from history change request.
    let viewContext = container.viewContext
    viewContext.perform {
      for transaction in history {
        viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
        self.lastToken = transaction.token
      }
    }
  }
  
}

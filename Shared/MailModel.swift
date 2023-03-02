import CoreData
import OSLog
import Combine
import MailCore


private let log = Logger(subsystem: "cum.expressyouryes.psymail", category: "MailModel")
private let cSentLabel = "\\Sent"


class MailModel: ObservableObject {
  @Published private(set) var emails:[String: [Email]] = [:]

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy' at 'H:mm:ss a zzz"
    return formatter
  }

  private var context: NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  
  // MARK: - PUBLIC
  
  func highestEmailUid() -> UInt64 {
    let request: NSFetchRequest<Email> = Email.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "uid", ascending: false)]
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    request.propertiesToFetch = ["uid"]

    return UInt64(try! context.fetch(request).first?.uid ?? 0)
  }
  
  func save() {
    try? context.save()
  }
  
  func addFlags(_ flags: MCOMessageFlag, for theEmails: [Email]) async throws {
    try await context.perform {
      theEmails.forEach { e in e.addFlags(flags) }
      
      do {
        try self.context.save()
      }
      catch {
        log.debug("error saving adding flags: \(error)")
        throw error
      }
    }
  }
  
  func deleteEmails(_ theEmails: [Email], _ completion: @escaping (Error?) -> Void) {
    context.performAndWait {
      for e in theEmails {
        e.addFlags(.deleted)
        e.trashed = true
      }
      
      do {
        try context.save()
        completion(nil)
      }
      catch let error {
        print("error deleting emails from core data: \(error.localizedDescription)")
        completion(error)
      }
    }
  }
  
  func saveNewMessages(_ messages: [MCOIMAPMessage], forAccount account: Account) async throws {
    let taskContext = PersistenceController.shared.newTaskContext()
    taskContext.name = "saveNewMessages"
    taskContext.transactionAuthor = "MailModel"
    
    try await taskContext.perform {
      let batchInsertRequest = self.newBatchInsertRequest(with: messages, context: taskContext)
      if let fetchResult = try? taskContext.execute(batchInsertRequest),
         let batchInsertResult = fetchResult as? NSBatchInsertResult,
         let success = batchInsertResult.result as? Bool, success {
        return
      }
      log.debug("failed to batch save new emails")
      throw PsyError.batchInsertError
    }
    
    log.info("done saving new emails")
  }
  
  private func newBatchInsertRequest(
    with messages: [MCOIMAPMessage], context: NSManagedObjectContext
  ) -> NSBatchInsertRequest {
    var index = 0
    let total = messages.count
    
    let batchInsertRequest = NSBatchInsertRequest(entity: Email.entity()) {
      (managedObject: NSManagedObject) -> Bool in
      guard index < total else { return true }
      
      let message = messages[index]
      let email = managedObject as! Email
      email.populate(
        message: message,
        html: self.headerAsHtml(message.header)
      )
      
      index += 1
      return false
    }
    return batchInsertRequest
  }
  
  @discardableResult
  func makeEmail(
    withMessage message: MCOIMAPMessage, html emailAsHtml: String = "", account: Account
  ) throws -> Email {
    guard fetchEmailByUid(message.uid, account: account) == nil else {
      throw PsyError.emailAlreadyExists
    }

    let email = Email(
      message: message, html: emailAsHtml, bundleName: bundleFor(message), context: context
    )
    email.account = account
    account.addToEmails(email)
    
    return email
  }
  
  func emailsFromSenderOf(_ email: Email) -> [Email] {
    let senderAddress = email.from?.address ?? email.sender?.address ?? ""
    if senderAddress.isEmpty { return [] }
    
    var predicate: NSPredicate
    let predicateFormatBase = "header.from.address == %@ OR header.sender.address == %@"
    
    let senderDisplayName = email.from?.displayName ?? email.sender?.displayName ?? ""
    if senderDisplayName.isEmpty {
      predicate = NSPredicate(
        format: predicateFormatBase,
        senderAddress,
        senderAddress
      )
    } else {
      predicate = NSPredicate(
        format: predicateFormatBase +
        " OR header.from.displayName == %@ OR header.sender.displayName == %@",
        senderAddress,
        senderAddress,
        senderDisplayName,
        senderDisplayName
      )
    }
    
    let emailFetchRequest:NSFetchRequest<Email> = Email.fetchRequest()
    emailFetchRequest.predicate = predicate
    
    do {
      return try context.fetch(emailFetchRequest)
    }
    catch let error {
      print("error fetching emails from sender: \(error.localizedDescription)")
    }
    
    return []
  }
  
  func email(id: Email.ID?) -> Email? {
    guard id != nil
    else { return nil }
    
    return emails["everything"]?.first(where: { $0.id == id }) ?? nil
  }
  
  // MARK: - private
  
  private
  func fetchEmailByUid(_ uid: UInt32, account: Account) -> Email? {
    let fetchRequest: NSFetchRequest<Email> = Email.fetchRequest()
    fetchRequest.predicate = NSPredicate(
      format: "uid == %d && account.address == %@",
      Int32(uid), account.address
    )
    do {
      return try context.fetch(fetchRequest).first
    }
    catch {
      print("error fetching email by uid: \(error.localizedDescription)")
    }
    
    return nil
  }
  
  private
  func bundleFor(_ message: MCOIMAPMessage, emailAsHtml: String = "") -> String? {
    let labels = message.gmailLabels as! [String]? ?? []
    
    if labels.contains(where: { $0 == cSentLabel }) {
      // don't put sent emails in a bundle
      return nil
    }
    
    if let bundleLabel = labels.first(where: { $0.contains("psymail") }) {
      return bundleLabel.replacing("psymail/", with: "")
    }
    
    return "inbox"
  }
  
  private
  func headerAsHtml(_ header: MCOMessageHeader) -> String {
    let from = header.from
    let to: String = addressesAsString(header.to as? [MCOAddress], prefix: "To: ")
    let cc: String = addressesAsString(header.cc as? [MCOAddress], prefix: "CC: ")
    let bcc: String = addressesAsString(header.bcc as? [MCOAddress], prefix: "BCC: ")
    
    return """
      From: \(from?.displayName ?? "") <\(from?.mailbox ?? "")\n
      \(to)
      \(cc)
      \(bcc)
      Subject: \(header.subject ?? "")\n
      Date: \(localizedDate(header.receivedDate))\n
    """
  }
  
  private
  func addressesAsString(_ addresses: [MCOAddress]?, prefix: String = "") -> String {
    var result = ""
    
    if let addresses = addresses {
      for a in addresses {
        result += "\(a.displayName ?? "") <\(a.mailbox ?? "")>, "
      }
    }
    
    return result.isEmpty ? "" : prefix + result + "\n"
  }
  
  private
  func localizedDate(_ date: Date?) -> String {
    return (date != nil) ? dateFormatter.string(from: date!) : ""
  }
  
}

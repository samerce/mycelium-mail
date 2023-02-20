//import CoreML
//import NaturalLanguage
import CoreData
import OSLog
import Combine
import MailCore


let Bundles = [
  "everything", "notifications", "commerce", "newsletters", "society", "marketing"
  //  "news", "trash", "folders", "sent"
]
private let log = Logger(subsystem: "cum.expressyouryes.psymail", category: "MailModel")


class MailModel: ObservableObject {
  @Published private(set) var emails:[String: [Email]] = [:]
  
  var lastSavedEmailUid: UInt64 {
    return 208000
//    guard let allEmails = emails["everything"]
//    else { return 0 }
//
//    if allEmails.count > 0 { return UInt64(allEmails.first!.uid) }
//    else { return 0 }
  } // TODO update to use core data fetch
  
  private var fetchers = [String: NSFetchedResultsController<Email>]()
  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy' at 'H:mm:ss a zzz"
    return formatter
  }
  //  private var oracle: NLModel?
  
  private var context: NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  
  func highestEmailUid() -> UInt64 {
    let request: NSFetchRequest<Email> = Email.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "uid", ascending: false)]
    request.fetchLimit = 1
    request.fetchBatchSize = 1
    request.propertiesToFetch = ["uid"]

    return UInt64(try! context.fetch(request).first?.uid ?? 0)
  }
  
  init() {
//    DispatchQueue.global(qos: .background).async {
//      self.context.performAndWait { () -> Void in
//        do {
//          let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Email.fetchRequest()
//          fetchRequest.fetchLimit = 108
//
//          let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//          try self.context.execute(deleteRequest)
//          print("deleted data")
//        }
//        catch {
//          print("error deleting all emails from core data: \(error)")
//        }
//      }
//    }
    
//    do {
//      oracle = try NLModel(mlModel: PsycatsJuice(configuration: MLModelConfiguration()).model)
//    }
//    catch let error {
//      print("error creating ai model: \(error)")
//    }
    
//    for bundle in Bundles {
//      emails[bundle] = fetchEmails(for: bundle)
//    }
  }
  
  // MARK: - public
  
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
        // TODO remove this deletion and instead
        // update the fetch predicate to omit all emails with that flag
        context.delete(e)
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
        html: self.headerAsHtml(message.header),
        bundle: self.bundleFor(message)
      )
      
      index += 1
      return false
    }
    return batchInsertRequest
  }
  
  func makeAndSaveEmail(withMessage message: MCOIMAPMessage, html emailAsHtml: String = "", account: Account) {
    do {
      let _ = try makeEmail(withMessage: message, html: emailAsHtml, account: account)
      try context.save()
      log.info("saved \(message.uid), \(message.header.subject ?? "")")
    }
    catch {
      log.debug("error saving new email to core data: \(error.localizedDescription)")
    }
  }
  
  func makeEmail(
    withMessage message: MCOIMAPMessage, html emailAsHtml: String = "", account: Account
  ) throws -> Email {
//    let fullHtml = headerAsHtml(message.header) + emailAsHtml
    let bundle = bundleFor(message)
    
    guard fetchEmailByUid(message.uid, account: account) == nil else {
      throw PsyError.emailAlreadyExists
    }
    
    let email = Email(
      message: message, html: emailAsHtml, bundle: bundle, context: context
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
    
    let emailFetchRequest:NSFetchRequest<Email> = Email.fetchRequestForBundle()
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
  
  func fetchMore(_ bundle: String) {
    guard let emailsInBundle = emails[bundle]
    else { return }
    //
    let emailCount = emailsInBundle.count
    //    let triggerFetchIndex = emailCount - 12
    //
    //    guard triggerFetchIndex >= 0 && triggerFetchIndex < emailCount
    //    else { return }
    //
    //    let triggerEmail = emailsInPerspective[triggerFetchIndex]
    //    if email.objectID == triggerEmail.objectID {
    //      print("\(perspective) fetching at offset: \(emailCount)")
    let newEmails = fetchEmails(for: bundle, offset: emailCount)
    emails[bundle]?.append(contentsOf: newEmails)
    //    }
  }
  
  func getEmails(for bundle: String) -> [Email] {
    var _emails = emails[bundle]
    if _emails == nil {
      _emails = fetchEmails(for: bundle)
    }
    return _emails!
  }
  
  // MARK: - private
  
  private
  func fetchEmails(for bundle: String, offset: Int = 0) -> [Email] {
    var _emails: [Email] = []
    
    do {
      let request = Email.fetchRequestForBundle(bundle, offset)
      _emails = try context.fetch(request)
      emails[bundle] = _emails
    }
    catch {
      print("error fetching emails from core data: \(error.localizedDescription)")
    }
    
    return _emails
  }
  
  private
  func fetchEmailByUid(_ uid: UInt32, account: Account) -> Email? {
    let fetchRequest: NSFetchRequest<Email> = Email.fetchRequest()
    fetchRequest.predicate = NSPredicate(
      format: "uid == %d && account.address == %@",
      Int32(uid), account.address ?? ""
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
  func bundleFor(_ message: MCOIMAPMessage, emailAsHtml: String = "") -> String {
    let labels = message.gmailLabels as! [String]? ?? []
    //    print("labels", labels)
    if let bundleLabel = labels.first(where: { $0.contains("psymail") }) {
      return bundleLabel.replacing("psymail/", with: "")
    }
    else {
      //      return predictedBundleFor(emailAsHtml)
      return "everything"
    }
  }
  
  private
  func predictedBundleFor(_ emailAsHtml: String = "") -> String {
    return ""
    //    let prediction = oracle?.predictedLabel(for: emailAsHtml) ?? ""
    //    if prediction == "" { return "everything" }
    //    return prediction
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

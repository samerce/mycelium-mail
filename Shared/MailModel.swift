import CoreML
import NaturalLanguage
import CoreData
import MailCore

let Bundles = [
  "notifications", "commerce", "everything", "newsletters", "society",
//  "marketing", "society", "news", "notifications", "everything",
//  "trash", "folders", "sent"
]

class MailModel: ObservableObject {
  @Published private(set) var emails:[String: [Email]] = [:]
  
  var lastSavedEmailUid: UInt64 {
    guard let allEmails = emails["everything"]
    else { return 0 }
    
    if allEmails.count > 0 { return UInt64(allEmails.first!.uid) }
    else { return 0 }
  } // TODO update to use core data fetch

  private var fetchers = [String: NSFetchedResultsController<Email>]()
  private let dateFormatter = DateFormatter()
  private var oracle: NLModel?
  
  private var context: NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  
  init() {
//    do {
//      let fetchRequest: NSFetchRequest<any NSFetchRequestResult> = Email.fetchRequest()
//      fetchRequest.fetchLimit = 54
//      
//      let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//      try context.execute(deleteRequest)
//    }
//    catch let error {
//      print("error deleting all emails from core data: \(error)")
//    }
    
    dateFormatter.dateFormat = "MMM d, yyyy' at 'H:mm:ss a zzz"
    
    do {
      oracle = try NLModel(mlModel: PsycatsJuice(configuration: MLModelConfiguration()).model)
    }
    catch let error {
      print("error creating ai model: \(error)")
    }
    
    for bundle in Bundles {
      emails[bundle] = fetchEmails(for: bundle)
    }
    
//    let email = self.emails["marketing"]?.first(where: { e in
//      e.subject.contains("Pre-enroll in The Freelancer")
//    })
//
//    print(email?.html)
  }
  
  // MARK: - public
  
  func addFlags(_ flags: MCOMessageFlag, for theEmails: [Email],
                _ completion: @escaping (Error?) -> Void) {
    context.performAndWait {
      theEmails.forEach { e in e.addFlags(flags) }
      
      do {
        try context.save()
        completion(nil)
      }
      catch let error as NSError {
        print("error saving new email to core data: \(error)")
        completion(error)
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
  
  func makeAndSaveEmail(withMessage message: MCOIMAPMessage, html emailAsHtml: String?,
                        account: Account) {
    let fullHtml = headerAsHtml(message.header) + (emailAsHtml ?? "")
    let bundle = bundleFor(message, emailAsHtml: fullHtml)
    
    guard fetchEmailByUid(message.uid, account: account) == nil else {
      print("tried to add email already stored in core data")
      return
    }
    
    let email = Email(
      message: message, html: emailAsHtml, bundle: bundle, context: context
    )
    email.account = account
    account.addToEmails(email)
    
    do {
      try context.save()
    }
    catch let error as NSError {
      print("error saving new email to core data: \(error)")
    }
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
    
    let emailFetchRequest:NSFetchRequest<Email> = Email.fetchRequestByDate()
    emailFetchRequest.predicate = predicate
    
    do {
      return try context.fetch(emailFetchRequest)
    }
    catch let error {
      print("error fetching emails from sender: \(error.localizedDescription)")
    }
    
    return []
  }
  
  func fetchMore(for bundle: String) {
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
  
  // MARK: - private
  
  private
  func fetchEmails(for bundle: String, offset: Int = 0) -> [Email] {
    let request = Email.fetchRequestByDate(offset: offset, for: bundle)
    
    do {
      return try context.fetch(request)
    }
    catch let error {
      print("error fetching emails from core data: \(error.localizedDescription)")
    }
    
    return []
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
    catch let error {
      print("error fetching email by uid: \(error.localizedDescription)")
    }
    
    return nil
  }
  
  private
  func bundleFor(_ emailAsHtml: String = "") -> String {
    let prediction = oracle?.predictedLabel(for: emailAsHtml) ?? ""
    if prediction == "" { return "everything" }
    return prediction
  }
  
  private
  func bundleFor(_ message: MCOIMAPMessage, emailAsHtml: String = "") -> String {
    let labels = message.gmailLabels as! [String]? ?? []
    print("labels", labels)
    if let bundleLabel = labels.first(where: { $0.contains("psymail") }) {
      return bundleLabel.replacing("psymail/", with: "")
    }
    else {
      return bundleFor(emailAsHtml)
    }
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

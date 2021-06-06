import CoreML
import NaturalLanguage
import CoreData
import MailCore

let PerspectiveCategories = [
  "DMs": Set(["Games", "Computers & Electronics", "DMs"]),
  "events": Set(["Travel", "events"]),
  "digests": Set(["Science", "Reference", "Pets & Animals", "Home & Garden", "Hobbies & Leisure", "Books & Literature", "Arts & Entertainment", "digests"]),
  "commerce": Set(["Shopping", "Online Communities", "Internet & Telecom", "Health", "Food & Drink", "Finance", "Business & Industrial", "Beauty & Fitness", "commerce"]),
  "society": Set(["Sports", "Sensitive Subjects", "People & Society", "News", "Law & Government", "Jobs & Education", "society"]),
  "marketing": Set(["marketing"]),
  "news": Set(["news"]),
  "notifications": Set(["notifications"]),
  "everything": Set([""]),
  "health": Set([""])
]
let Tabs = [
  "society", "events", "digests", "commerce", "DMs",
  "marketing", "health", "news", "notifications", "everything"
]

class MailModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
  @Published private(set) var emails:[String: [Email]] = [:]
  
  var lastSavedEmailUid: UInt64 {
    let allEmails = emails["everything"]!
    if allEmails.count > 0 { return UInt64(allEmails.first!.uid) }
    else { return 0 }
  } // TODO update to use core data fetch

  private var fetchers = [String: NSFetchedResultsController<Email>]()
  private let dateFormatter = DateFormatter()
  private var oracle: NLModel?
  
  private var moc:NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  
  override init() {
    super.init()
//    do {
//      let deleteRequest = NSBatchDeleteRequest(fetchRequest: Email.fetchRequest())
//      try moc.execute(deleteRequest)
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
    
    for (perspective, _) in PerspectiveCategories {
      self.emails[perspective] = fetcherFor(perspective)
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
    moc.performAndWait {
      theEmails.forEach { e in e.addFlags(flags) }
      
      do {
        try moc.save()
        completion(nil)
      }
      catch let error as NSError {
        print("error saving new email to core data: \(error)")
        completion(error)
      }
    }
  }
  
  func deleteEmails(_ theEmails: [Email], _ completion: @escaping (Error?) -> Void) {
    moc.performAndWait {
      for e in theEmails {
        e.addFlags(.deleted)
        // TODO remove this deletion and instead
        // update the fetch predicate to omit all emails with that flag
        moc.delete(e)
      }
      
      do {
        try moc.save()
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
    let perspective = perspectiveFor(fullHtml)
    
    guard fetchEmailByUid(message.uid, account: account) == nil else {
      print("tried to add email already stored in core data")
      return
    }
    
    let email = Email(
      message: message, html: emailAsHtml, perspective: perspective, context: moc
    )
    email.account = account
    account.addToEmails(email)
    
    do {
      try moc.save()
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
      return try moc.fetch(emailFetchRequest)
    }
    catch let error {
      print("error fetching emails from sender: \(error.localizedDescription)")
    }
    
    return []
  }
  
  // MARK: - private
  
  private func fetcherFor(_ perspective: String) -> [Email] {
    let request = Email.fetchRequestByDateAndPerspective(perspective)
    let fetcher = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: moc,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
    fetcher.delegate = self
    self.fetchers[perspective] = fetcher
    
    do {
      try fetcher.performFetch()
      return fetcher.fetchedObjects!
    }
    catch let error {
      print("error fetching emails from core data: \(error.localizedDescription)")
    }
    
    return []
  }
  
  private func fetchEmailsByDateDescending() -> [Email] {
    do {
      return try moc.fetch(Email.fetchRequestByDate())
    }
    catch let error {
      print("error fetching emails from core data: \(error.localizedDescription)")
    }
    
    return []
  }
  
  private func fetchEmailByUid(_ uid: UInt32, account: Account) -> Email? {
    let fetchRequest: NSFetchRequest<Email> = Email.fetchRequest()
    fetchRequest.predicate = NSPredicate(
      format: "uid == %d && account.address == %@",
      Int32(uid), account.address ?? ""
    )
    do {
      return try moc.fetch(fetchRequest).first
    }
    catch let error {
      print("error fetching email by uid: \(error.localizedDescription)")
    }
    
    return nil
  }
  
  private func perspectiveFor(_ emailAsHtml: String = "") -> String {
    let prediction = oracle?.predictedLabel(for: emailAsHtml) ?? ""
    if prediction == "" { return "other" }
    
    for (perspective, categorySet) in PerspectiveCategories {
      if categorySet.contains(prediction) {
        return perspective
      }
    }
    return "other"
  }
  
  private func headerAsHtml(_ header: MCOMessageHeader) -> String {
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
  
  private func addressesAsString(_ addresses: [MCOAddress]?, prefix: String = "") -> String {
    var result = ""

    if let addresses = addresses {
      for a in addresses {
        result += "\(a.displayName ?? "") <\(a.mailbox ?? "")>, "
      }
    }
    
    return result.isEmpty ? "" : prefix + result + "\n"
  }
  
  private func localizedDate(_ date: Date?) -> String {
    return (date != nil) ? dateFormatter.string(from: date!) : ""
  }
  
  // MARK: - NSFetchedResultsController delegate
  
  func controllerDidChangeContent(_ theFetcher: NSFetchedResultsController<NSFetchRequestResult>) {
    for (perspective, fetcher) in fetchers {
      if theFetcher == fetcher {
        emails[perspective] = fetcher.fetchedObjects ?? emails[perspective]
      }
    }
  }
  
}

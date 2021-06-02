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
  "everything": Set([""])
]
let Tabs = [
  "DMs", "events", "digests", "commerce", "society",
  "marketing", "news", "notifications", "everything"
]

class MailModel: ObservableObject {
  @Published private(set) var sortedEmails:[String: [Email]] = [:]
  @Published var selectedEmail: Email?
  
  var lastSavedEmailUid: UInt64 {
    if emails.count > 0 { return UInt64(emails.first!.uid) }
    else { return 71000 }
  }

  private let dateFormatter = DateFormatter()
  private var oracle: NLModel?
  
  private var managedContext:NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  private var emails: [Email] {
    sortedEmails["everything"] ?? []
  }
  
  init() {
    dateFormatter.dateFormat = "MMM d, yyyy' at 'H:mm:ss a zzz"
    
    for (perspective, _) in PerspectiveCategories {
      self.sortedEmails[perspective] = []
    }
    
    for email in fetchEmailsByDateDescending() {
      let perspective = email.perspective ?? ""
      self.sortedEmails[perspective]?.insert(email, at: 0)
      self.sortedEmails["everything"]?.insert(email, at: 0)
    }

    do {
      oracle = try NLModel(mlModel: PsycatsJuice(configuration: MLModelConfiguration()).model)
    }
    catch let error {
      print("error creating ai model: \(error)")
    }
    
//    do {
//      let deleteRequest = NSBatchDeleteRequest(fetchRequest: Email.fetchRequest())
//      try managedContext.execute(deleteRequest)
//    }
//    catch let error {
//      print("error fetching emails from core data: \(error)")
//    }
  }
  
  // MARK: - public
  
  func markSeen(_ emails: [Email]) -> Error? {
    for email in emails { email.setFlags([.seen]) }
    do {
      try managedContext.save()
    }
    catch let error {
      return error
    }
    return nil
  }
  
  func makeAndSaveEmail(
    withMessage message: MCOIMAPMessage, html emailAsHtml: String?, account: Account
  ) {
    let fullHtml = headerAsHtml(message.header) + (emailAsHtml ?? "")
    let perspective = perspectiveFor(fullHtml)
    
    let email = Email(
      message: message, html: emailAsHtml, perspective: perspective, context: managedContext
    )
    email.account = account
    account.addToEmails(email)
    
    do {
      try managedContext.save()
      sortedEmails[perspective]?.insert(email, at: 0)
      sortedEmails["everything"]?.insert(email, at: 0)
    }
    catch let error as NSError {
      print("error saving new email to core data: \(error)")
    }
  }
  
  // MARK: - private
  
  private func fetchEmailsByDateDescending() -> [Email] {
    let emailFetchRequest:NSFetchRequest<Email> = Email.fetchRequest()
    emailFetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
    
    do {
      return try managedContext.fetch(emailFetchRequest)
    }
    catch let error {
      print("error fetching emails from core data: \(error.localizedDescription)")
    }
    
    return []
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
  
}

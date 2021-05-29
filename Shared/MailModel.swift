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
  var mostRecentSavedUid: UInt64 = 70700
  
  private var oracle: NLModel?
  private var managedContext:NSManagedObjectContext {
    PersistenceController.shared.container.viewContext
  }
  private var emails: [Email] {
    sortedEmails["everything"] ?? []
  }
  
  init() {
    do {
      oracle = try NLModel(mlModel: PsycatsJuice(configuration: MLModelConfiguration()).model)
    }
    catch let error {
      print("error creating ai model: \(error)")
    }
    
    for (perspective, _) in PerspectiveCategories {
      self.sortedEmails[perspective] = []
    }
    
    do {
//      let deleteRequest = NSBatchDeleteRequest(fetchRequest: Email.fetchRequest())
//      try managedContext.execute(deleteRequest)
      
      let emailFetchRequest:NSFetchRequest<Email> = Email.fetchRequest()
      emailFetchRequest.sortDescriptors = [NSSortDescriptor(key: "uid", ascending: true)]
      let fetchedEmails = try managedContext.fetch(Email.fetchRequest()) as [Email]
      for email in fetchedEmails {
        let perspective = email.perspective ?? ""
        self.sortedEmails[perspective]?.insert(email, at: 0)
        self.sortedEmails["everything"]?.insert(email, at: 0)
      }
      
      updateMostRecentSavedUid()
    }
    catch let error {
      print("error fetching emails from core data: \(error)")
    }
  }
  
  // MARK: - public
  
  func markSeen(_ emails: [Email]) -> Error? {
    for email in emails { email.markSeen() }
    do {
      try managedContext.save()
    }
    catch let error {
      return error
    }
    return nil
  }
  
  func makeAndSaveEmail(withMessage message: MCOIMAPMessage, html emailAsHtml: String?) {
    let perspective = perspectiveFor(emailAsHtml ?? "")
    let email = Email(
      message: message, html: emailAsHtml, perspective: perspective, context: managedContext
    )
    
    do {
      try managedContext.save()
      sortedEmails[perspective]?.insert(email, at: 0)
      sortedEmails["everything"]?.insert(email, at: 0)
      
      updateMostRecentSavedUid()
    }
    catch let error as NSError {
      print("error saving new email to core data: \(error)")
    }
  }
  
  // MARK: - private
  
  private func perspectiveFor(_ emailAsHtml: String = "") -> String {
    let prediction = oracle?.predictedLabel(for: emailAsHtml) ?? ""
    for (perspective, categorySet) in PerspectiveCategories {
      if categorySet.contains(prediction) {
        return perspective
      }
    }
    return "other"
  }
  
  private func updateMostRecentSavedUid() {
    if let uid = emails.first?.uid {
      mostRecentSavedUid = UInt64(uid)
    }
  }
  
}

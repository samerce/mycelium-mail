import CoreML
import NaturalLanguage
import CoreData
import GoogleSignIn
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

struct Email {
  var uid: UInt32
  var message: MCOIMAPMessage
  var html: String
}

class MailModel: NSObject, ObservableObject, GIDSignInDelegate, MCOHTMLRendererIMAPDelegate {
  private var persistenceController = PersistenceController.shared
  private var accessToken: String = ""
  private var oracles: [String: NLModel] = [:]
  private var oracle: NLModel?
  private var session: MCOIMAPSession = MCOIMAPSession()
  
  private(set) var emails: [UInt32: Email] = [:]
  @Published private(set) var sortedEmails:[String: [Email]] = [:]
  
  override init() {
    super.init()
    
    session.hostname = "imap.gmail.com"
    session.port = 993
    session.username = "samerce@gmail.com"
    session.authType = .xoAuth2
    session.connectionType = .TLS
    
    GIDSignIn.sharedInstance().clientID = "941559531688-m6ve00j5ofshqf5ksfqng92ga7kbkbb6.apps.googleusercontent.com"
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().scopes = [
      "https://mail.google.com/"
    ]
    
    do {
      oracle = try NLModel(mlModel: PsycatsJuice(configuration: MLModelConfiguration()).model)
    } catch {
    }
    for (perspective, _) in PerspectiveCategories {
      self.sortedEmails[perspective] = []
    }
  }
  
  func signIn() {
    GIDSignIn.sharedInstance().restorePreviousSignIn()
  }
  
  private func sortEmails() {
    for (_, email) in emails {
      let perspective = perspectiveFor(email.html)
      sortedEmails[perspective]?.insert(email, at: 0)
      sortedEmails["everything"]?.insert(email, at: 0)
    }
  }
  
  // MARK: - Helpers
  
  func perspectiveFor(_ email: String = "") -> String {
    let prediction = oracle?.predictedLabel(for: email) ?? ""
    for (perspective, categorySet) in PerspectiveCategories {
      if categorySet.contains(prediction) {
        return perspective
      }
    }
    return "other"
  }
  
  func fullHtmlFor(_ message: MCOIMAPMessage, _ completion: @escaping (String?) -> Void) {
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: message.uid)
    fetchMessage?.start({ (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlRendering(with: nil) ?? "")
    }) ?? completion("")
  }
  
  func bodyHtmlFor(_ message: MCOIMAPMessage, _ completion: @escaping (String?) -> Void) {
    let fetchMessage = session.fetchParsedMessageOperation(withFolder: "INBOX", uid: message.uid)
    fetchMessage?.start({ (error: Error?, parser: MCOMessageParser?) in
      completion(parser?.htmlBodyRendering() ?? "")
    }) ?? completion("")
  }
  
  func markSeen(_ email: Email) {
    let updateFlags = session.storeFlagsOperation(
      withFolder: "INBOX", uids: MCOIndexSet(index: UInt64(email.uid)), kind: .set, flags: .seen
    )
    updateFlags?.start { error in
      if error != nil {
        print("Error updating seen flag: \(String(describing: error))")
        return
      }
      email.message.flags.insert(.seen)
    }
  }
  
  // MARK: - google
  
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    if let error = error {
      if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
        print("The user has not signed in before or they have since signed out.")
      } else {
        print("\(error.localizedDescription)")
      }
      return
    }

//    let userId = user.userID                  // For client-side use only!
//    let fullName = user.profile.name
//    let givenName = user.profile.givenName
//    let familyName = user.profile.familyName
//    let email = user.profile.email
//    let context = persistenceController.container.viewContext
//    let entity = NSEntityDescription.entity(forEntityName: "GoogleAccessToken", in: context)!
//    let token = NSManagedObject(entity: entity, insertInto: context)
//    token.setValue(accessToken, forKeyPath: "value")
//
//    do {
//      try context.save()
//    } catch let error as NSError {
//      print("Could not save. \(error), \(error.userInfo)")
//    }
//
//    var googleAccessToken: String = ""
//    do {
//      let context = persistenceController.container.viewContext
//      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GoogleAccessToken")
//      let googleAccessTokens = try context.fetch(fetchRequest)
//      if (googleAccessTokens.count > 0) {
//        googleAccessToken = googleAccessTokens[0].value(forKey: "value") as! String
//      }
//    } catch let error as NSError {
//      print("Could not fetch. \(error), \(error.userInfo)")
//    }
    
    accessToken = user.authentication.accessToken // Safe to send to the server
    session.oAuth2Token = accessToken
    fetchLatest()
  }
  
  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    // Perform any operations when the user disconnects from app here.
  }
  
  var uids = MCOIndexSet(range: MCORangeMake(70500, UINT64_MAX))
  
  func fetchLatest() {
    print("fetching")
    let fetchHeadersAndFlags = session.fetchMessagesOperation(
      withFolder: "INBOX", requestKind: [.fullHeaders, .flags], uids: uids
    )
    fetchHeadersAndFlags?.start(didReceiveHeadersAndFlags)
  }
  
  func didReceiveHeadersAndFlags(error: Error?, messages: [MCOIMAPMessage]?, vanishedMessages: MCOIndexSet?) {
    if error != nil {
      print("Error downloading message headers: \(String(describing: error))")
      return
    }
    
    for message in messages! {
      fullHtmlFor(message) { emailAsHtml in
        let email = Email(uid: message.uid, message: message, html: emailAsHtml ?? "")
        let perspective = self.perspectiveFor(emailAsHtml ?? "")
        self.sortedEmails[perspective]?.insert(email, at: 0)
        self.sortedEmails["everything"]?.insert(email, at: 0)
        
        if message == messages?.last {
          print("done fetching!")
        }
      }
    }
  }
  
}

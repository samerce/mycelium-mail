import Postal
import CoreML
import NaturalLanguage
import CoreData
import GoogleSignIn

struct PostalAdaptor {
  private var postal: Postal
  
}

let PerspectiveCategories = [
  "DMs": Set(["Games", "Computers & Electronics", "DMs"]),
  "events": Set(["Travel", "events"]),
  "digests": Set(["Science", "Reference", "Pets & Animals", "Home & Garden", "Hobbies & Leisure", "Books & Literature", "Arts & Entertainment", "digests"]),
  "commerce": Set(["Shopping", "Online Communities", "Internet & Telecom", "Health", "Food & Drink", "Finance", "Business & Industrial", "Beauty & Fitness", "commerce"]),
  "society": Set(["Sports", "Sensitive Subjects", "People & Society", "News", "Law & Government", "Jobs & Education", "society"]),
  "marketing": Set(["marketing"]),
  "news": Set(["news"]),
  "notifications": Set(["notifications"])
]

class MailModel: NSObject, ObservableObject, GIDSignInDelegate {
  var persistenceController = PersistenceController.shared
  
  private var accessToken: String = ""
  private var oracles: [String: NLModel] = [:]
  private var oracle: NLModel?
  
  @Published private(set) var emails: [FetchResult] = []
  @Published private(set) var sortedEmails:[String: [FetchResult]] = [:]
  
  override init() {
    super.init()
    GIDSignIn.sharedInstance().clientID = "941559531688-m6ve00j5ofshqf5ksfqng92ga7kbkbb6.apps.googleusercontent.com"
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().scopes = [
      "https://mail.google.com/"
    ]
    
    do {
      oracle = try NLModel(mlModel: PsycatsJuice(configuration: MLModelConfiguration()).model)
//      let models = [
//        "newsletters": try? NewsletterClassifier(
//          configuration: MLModelConfiguration()
//        ).model,
//        "politics": try? PoliticsRecognizer(
//          configuration: MLModelConfiguration()
//        ).model,
//        "marketing": try? MarketingRecognizer(
//          configuration: MLModelConfiguration()
//        ).model,
//        "other": nil
//      ]
//      for (category, mlModel) in models {
//        if mlModel != nil {
//          oracles[category] = try NLModel(mlModel: mlModel!)
//        }
//        sortedEmails[category] = []
//      }
    } catch {
    }
    for (perspective, _) in PerspectiveCategories {
      self.sortedEmails[perspective] = []
    }
  }
  
  func signIn() {
    GIDSignIn.sharedInstance().restorePreviousSignIn()
  }
  
  func sortEmails() {
    for email in self.emails {
      let perspective = perspectiveFor(emailAsString(email))
      self.sortedEmails[perspective]?.insert(email, at: 0)
    }
  }
  
  // MARK: - Helpers
  
  func emailAsString(_ msg: FetchResult) -> String {
    if msg.body == nil || msg.header == nil { return "" }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
    let date = dateFormatter.date(from: (msg.header?.receivedDate!.description)!) ?? Date()
    
    var from = ""
    if (msg.header?.from.count ?? 0) > 0 {
      from = msg.header?.from[0].email ?? ""
    }
    
    var to = ""
    if (msg.header?.to.count ?? 0) > 0 {
      to = msg.header?.to[0].email ?? ""
    }
    
    return """
          From: \(from)
          Subject: \(msg.header?.subject ?? "")
          Date: \(date)
          To: \(to)\n
          \(htmlFor(msg))
      """
  }
  
  func perspectiveFor(_ email: String) -> String {
    let prediction = oracle?.predictedLabel(for: email) ?? ""
    for (perspective, categorySet) in PerspectiveCategories {
      if categorySet.contains(prediction) {
        return perspective
      }
    }
    return "other"
    
    //        var bestPredictionConfidence = 0
    
//    for (category, oracle) in self.oracles {
//      let prediction = oracle.predictedLabel(for: email)
//      if prediction == "yes" /*&& prediction!.confidence > bestPredictionConfidence*/ {
//        categoryPrediction = category
//        //                bestPredictionConfidence = prediction.confidence
//      }
//    }
//
//    return categoryPrediction
  }
  
  func htmlFor(_ message: FetchResult) -> String {
    var html = ""
    let htmlPart = message.body?.allParts.first(where: { part in
      part.mimeType.subtype == "html"
    })
    if (htmlPart?.data != nil) {
      let rawDataAsHtmlString: String = String(data: (htmlPart?.data!.rawData)!, encoding: .utf8)!
      html = QuotedPrintable.decode(rawDataAsHtmlString)
    }
    return html
  }
  
  func getMessage(_ messageUID: UInt, _ completion: @escaping (FetchResult) -> Void) {
    var configuration: Configuration! {
      .gmail(
        login: "samerce@gmail.com",
        password: .accessToken(accessToken)
      )
    }
    let postal = Postal(configuration: configuration)
    postal.connect(timeout: Postal.defaultTimeout, completion: { result in
      switch result {
      case .success:
        postal.fetchMessages("INBOX", uids: IndexSet([Int(messageUID)]), flags: [.body],
                             onMessage: { result in completion(result) },
                             onComplete: { error in print(error ?? "") })
        
      case .failure(let error):
        print(error)
      }
    })
  }
  
  // MARK: - google
  
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
            withError error: Error!) {
    if let error = error {
      if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
        print("The user has not signed in before or they have since signed out.")
      } else {
        print("\(error.localizedDescription)")
      }
      return
    }
    // Perform any operations on signed in user here.
//    let userId = user.userID                  // For client-side use only!
    accessToken = user.authentication.accessToken // Safe to send to the server
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
    
    var configuration: Configuration! {
      .gmail(
        login: "samerce@gmail.com",
        password: .accessToken(accessToken)
      )
    }
    let postal = Postal(configuration: configuration)
    postal.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
      switch result {
      case .success:
        postal.fetchLast("INBOX", last: 400, flags: [.flags, .fullHeaders, .internalDate, .body],
                         onMessage: { email in self?.emails.append(email) },
                         onComplete: { error in self?.sortEmails() })
        
      case .failure(let error):
        print(error)
      }
    })
  }
  
  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
            withError error: Error!) {
    // Perform any operations when the user disconnects from app here.
    // ...
  }
  
}

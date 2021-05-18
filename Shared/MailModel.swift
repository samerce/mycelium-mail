import Postal
import CoreML
import NaturalLanguage
import CoreData
import GoogleSignIn

struct PostalAdaptor {
  private var postal: Postal
  
}

class MailModel: NSObject, ObservableObject, GIDSignInDelegate {
  var persistenceController = PersistenceController.shared
  
  private var accessToken: String = ""
  private var oracles: [String: NLModel] = [:]
  
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
      let models = [
        "newsletters": try? NewsletterClassifier(
          configuration: MLModelConfiguration()
        ).model,
        "politics": try? PoliticsRecognizer(
          configuration: MLModelConfiguration()
        ).model,
        "marketing": try? MarketingRecognizer(
          configuration: MLModelConfiguration()
        ).model,
        "other": nil
      ]
      for (category, mlModel) in models {
        if mlModel != nil {
          oracles[category] = try NLModel(mlModel: mlModel!)
        }
        sortedEmails[category] = []
      }
    } catch {
      
    }
  }
  
  func signIn() {
    GIDSignIn.sharedInstance().restorePreviousSignIn()
  }
  
  func sortEmails() {
    for email in self.emails {
      let emailString = getEmailString(email)
      let aiCategory = getSmartCategory(emailString)
      self.sortedEmails[aiCategory]?.insert(email, at: 0)
    }
  }
  
  // MARK: - Helpers
  
  func getEmailString(_ msg: FetchResult) -> String {
    if msg.body == nil || msg.header == nil { return "" }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
    let date = dateFormatter.date(from: (msg.header?.receivedDate!.description)!) ?? Date()
    return """
          From: \(msg.header!.from[0].email)
          Subject: \(msg.header!.subject)
          Date: \(date)
          To: \(msg.header!.to[0].email)\n
          \(msg.body!)
      """
  }
  
  func getSmartCategory(_ email: String) -> String {
    var categoryPrediction = "other"
    //        var bestPredictionConfidence = 0
    
    for (category, oracle) in self.oracles {
      let prediction = oracle.predictedLabel(for: email)
      if prediction == "yes" /*&& prediction!.confidence > bestPredictionConfidence*/ {
        categoryPrediction = category
        //                bestPredictionConfidence = prediction.confidence
      }
    }
    
    return categoryPrediction
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
//    postal.listFolders({ result in
//      switch result {
//      case .success:
//        print(result)
//      case .failure(let error):
//        print(error)
//      }
//    })
    postal.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
      switch result {
      case .success:
        postal.fetchLast("INBOX", last: 300, flags: [.flags, .fullHeaders, .internalDate],
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

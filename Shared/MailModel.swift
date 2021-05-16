import Postal
import CreateML
import CoreML
import NaturalLanguage

class MailModel: ObservableObject {
    private var configuration: Configuration! {
        .gmail(login: "samerce@gmail.com", password: .accessToken("ya29.a0AfH6SMCVwvorYw74djFb9LZqKhRgjbWJzG9rYxgT0HzstN0WTT-doBDwO-vQUD9jlceE7qFC13D5qEABtrlBGCGTTQpZWXec_vbTpOFMOo4pAEZiUiqGqbYvmVBx8xSBlKDVzVrYskGv7S_iZXaTpo490I0i"))
    }
    
    fileprivate lazy var postal: Postal = Postal(configuration: self.configuration)
    private var oracles:[String: NLModel] = [:]
    
    @Published private(set) var emails: [FetchResult] = []
    @Published private(set) var sortedEmails:[String: [FetchResult]] = [:]
    
    init() {
        self.initSortingMagic()
        
        postal.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
            switch result {
            case .success:
                self?.postal.fetchLast("INBOX", last: 100, flags: [ .fullHeaders ],
                    onMessage: { email in self?.emails.insert(email, at: 0) },
                    onComplete: { error in self?.sortEmails() })

            case .failure(let error):
                print(error)
            }
        })
    }
    
    func initSortingMagic() {
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
                    self.oracles[category] = try NLModel(mlModel: mlModel!)
                }
                self.sortedEmails[category] = []
            }
        } catch {
            
        }
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
    
}

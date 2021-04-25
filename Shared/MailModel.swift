import Postal
import CreateML
import CoreML
import NaturalLanguage

class MailModel: ObservableObject {
    private var configuration: Configuration! {
        .gmail(login: "samerce@gmail.com", password: .accessToken("ya29.a0AfH6SMDN7uoD5JkKml4cP4RWl6sufcwwQwqKSqQ0Io7Z9YagwmEvJqz2nquEes44NV6yPkSSRc366L4k1-hgs-p3xcRwurAFHsyigNYfOZm8U3ensTAFowr19zKDzTbdRCcal_l_FZr3YVRchVLNk1I4adOp"))
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
                if mlModel == nil { continue }
                self.oracles[category] = try NLModel(mlModel: mlModel!)
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let date = dateFormatter.date(from: (msg.header?.receivedDate!.description)!)
        return """
            From: \(msg.header?.from[0].email)
            Subject: \(msg.header?.subject)
            Date: \(date)
            To: \(msg.header?.to[0].email)\n
            \(msg.body)
        """
    }
    
    func getSmartCategory(_ email: String) -> String {
        var categoryPrediction = "other"
//        var bestPredictionConfidence = 0
        
        for (category, oracle) in self.oracles {
            do {
                let prediction = oracle.predictedLabel(for: email)
                if prediction == "yes" /*&& prediction!.confidence > bestPredictionConfidence*/ {
                    categoryPrediction = category
//                    bestPredictionConfidence = prediction.confidence
                }
            } catch {
                
            }
        }
        
        return categoryPrediction
    }
    
    // MARK: - API
    
}

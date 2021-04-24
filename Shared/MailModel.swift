import Postal

class MailModel: ObservableObject {
    var configuration: Configuration! {
        .gmail(login: "samerce@gmail.com", password: .accessToken("ya29.a0AfH6SMB5gPPCI0Gsgfl-vmA9in1gFKs_qY3XI6H5dp3_7748y2J5nBVWlIoiAziMpz1YXDFxNEDRybOyWyGUxTmOdFFn0-GcW_EdQc5l0JEERMjgRB8HYwrw-Bn3DIKLPWJDTtCwtGqPL2DaUMeOMN6iFe4D"))
    }
    
    fileprivate lazy var postal: Postal = Postal(configuration: self.configuration)
    @Published private(set) var messages: [FetchResult] = []
    
    init() {
        postal.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
            switch result {
            case .success:
                self?.postal.fetchLast("INBOX", last: 50, flags: [ .fullHeaders ], onMessage: { message in
                    self?.messages.insert(message, at: 0)
                    
                    }, onComplete: { error in
//                        if let error = error {
//                            self?.showAlertError("Fetch error", message: (error as NSError).localizedDescription)
//                        } else {
//                            self?.tableView.reloadData()
//                        }
                })

            case .failure(let error):
                print(error)
//                self?.showAlertError("Connection error", message: (error as NSError).localizedDescription)
            }
        })
    }
    
    // MARK: - API
    
    
}

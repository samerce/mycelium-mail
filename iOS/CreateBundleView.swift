import SwiftUI
import CoreData
import SymbolPicker
import Combine


private let mailCtrl = MailController.shared
private let dataCtrl = PersistenceController.shared


struct CreateBundleView: View {
  @Environment(\.managedObjectContext) var moc: NSManagedObjectContext
  @ObservedObject var bundleCtrl = BundleController.shared
  @ObservedObject var alertCtrl = AlertController.shared
  @ObservedObject var sheetCtrl = SheetController.shared
  @ObservedObject var accountCtrl = AccountController.shared
  
  @FocusState var bundleNameFocused
  @State var bundleName = ""
  @State var iconPickerPresented = false
  @State var icon = "sparkle"
  @State var processing = false
  @State var selectedAccount: Account
  
  var accounts: [Account] {
    accountCtrl.accounts.values.map { $0 }
  }
  
  
  init() {
    selectedAccount = AccountController.shared.accounts.values.map({ $0 }).first!
  }

  // MARK: - VIEW
  
  var body: some View {
    if processing {
      VStack {
        ProgressView("CREATING BUNDLE")
          .controlSize(.large)
      }
      .frame(maxHeight: .infinity, alignment: .center)
    } else {
      CreateForm
    }
  }
  
  var CreateForm: some View {
    VStack(alignment: .center, spacing: 0) {
      SheetHandle()
        .padding(.top, 6)
        .padding(.bottom, 9)
      
      Text("create new bundle")
        .font(.system(size: 27, weight: .black))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 18)
      
      Picker("account", selection: $selectedAccount) {
        ForEach(accounts) {
          Text($0.address).tag($0)
            .foregroundColor(.psyAccent)
        }
      }
      .tint(.psyAccent)
      .padding(.bottom, 18)
      
      VStack(spacing: 18) {
        Button {
          iconPickerPresented = true
        } label: {
          SystemImage(name: icon, size: 27)
        }
        .buttonStyle(.bordered)
        
        bundleNameField
      }
      .padding(.bottom, 18)
      
      HStack {
        Button("cancel") {
          withAnimation {
            sheetCtrl.sheet = .inbox
          }
        }
        .buttonStyle(.bordered)
        .tint(.gray)

        Button("create") {
          createBundle()
        }
        .buttonStyle(.borderedProminent)
      }
      
      Spacer()
    }
    .frame(maxHeight: .infinity)
    .padding(.horizontal, 12)
    .sheet(isPresented: $iconPickerPresented) {
      SymbolPicker(symbol: $icon)
        .foregroundColor(.psyAccent)
    }
  }
  
  var bundleNameField: some View {
    TextField("name", text: $bundleName)
      .frame(maxWidth: 216)
      .textFieldStyle(.roundedBorder)
      .multilineTextAlignment(.center)
      .font(.system(size: 18, weight: .semibold))
      .submitLabel(.done)
      .tint(.psyAccent)
      .focused($bundleNameFocused)
      .onAppear {
        bundleNameFocused = true
      }
      .onSubmit {
        createBundle()
      }
  }
  
  func createBundle() {
    processing = true
    
    Task {
      do {
        let bundle = try await getOrMakeBundleNamed(bundleName)

        if let thread = bundleCtrl.threadToMoveToNewBundle {
          // TODO: get bundle from initiating context
          mailCtrl.moveThread(thread, toBundle: bundle, fromBundle: thread.bundle)
          bundleCtrl.threadToMoveToNewBundle = nil
          
          Timer.after(1) { _ in
            DispatchQueue.main.async {
              alertCtrl.show(message: "moved to new bundle\n\(bundle.name.uppercased())", icon: icon)
            }
          }
        } else {
          Timer.after(1) { _ in
            DispatchQueue.main.async {
              alertCtrl.show(message: "\(bundleName.uppercased())\nbundle created", icon: icon)
            }
          }
        }
      }
      catch {
        print("bundle creation failed: \(error.localizedDescription)")
        alertCtrl.show(message: "failed to create bundle", icon: "xmark")
      }
      
      withAnimation {
        sheetCtrl.sheet = .inbox
      }
    }
    
  }
  
  func getOrMakeBundleNamed(_ name: String) async throws -> EmailBundle {
    var bundle = bundleCtrl.bundles.first(where: { $0.name == name })
    
    if bundle == nil {
      let label = try await selectedAccount.createLabel("psymail/\(name)")
      bundle = EmailBundle(
        name: name, labelId: label.id, icon: icon, orderIndex: bundleCtrl.bundles.count, context: moc
      )
      try moc.save()
    }
    
    if bundle == nil {
      throw PsyError.unexpectedError(message: "new bundle should exist")
    }
    return bundle!
  }
  
}

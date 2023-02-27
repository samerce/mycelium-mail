import SwiftUI
import CoreData
import SymbolPicker
import Combine


private let mailCtrl = MailController.shared
private let dataCtrl = PersistenceController.shared


struct CreateBundleView: View {
  
  @Environment(\.managedObjectContext) var moc: NSManagedObjectContext
  @EnvironmentObject var viewModel: ViewModel
  @EnvironmentObject var alert: AppAlertViewModel
  
  @FocusState var bundleNameFocused
  @State var bundleName = ""
  @State var account: Account
  @State var iconPickerPresented = false
  @State var icon = "sparkle"
  @State var processing = false
  
  var allAccounts: [Account]
  
  init() {
    allAccounts = AccountController.shared.model.accounts.map { $1 }
    account = allAccounts.first!
  }
  
  var body: some View {
    if processing {
      VStack {
        ProgressView("CREATING BUNDLE")
          .controlSize(.large)
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      CreateForm
    }
  }
  
  var CreateForm: some View {
    VStack(alignment: .center, spacing: 0) {
      DragSheetIcon()
        .padding(.top, 6)
        .padding(.bottom, 9)
      
      Text("create new bundle")
        .font(.system(size: 27, weight: .black))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 18)
      
      Picker("account", selection: $account) {
        ForEach(allAccounts) {
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
            viewModel.appSheet = .inboxTools
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

        if let email = viewModel.emailToMoveToNewBundle {
          // TODO: get bundle from initiating context
          try await mailCtrl.moveEmail(email, fromBundle: email.bundles.first!, toBundle: bundle)
          viewModel.emailToMoveToNewBundle = nil
          
          Timer.after(1) { _ in
            DispatchQueue.main.async {
              alert.show(message: "moved to new bundle\n\(bundle.name.uppercased())", icon: icon)
            }
          }
        } else {
          Timer.after(1) { _ in
            DispatchQueue.main.async {
              alert.show(message: "\(bundleName.uppercased())\nbundle created", icon: icon)
            }
          }
        }
      }
      catch {
        print("bundle creation failed: \(error.localizedDescription)")
        alert.show(message: "failed to create bundle", icon: "xmark")
      }
      
      withAnimation {
        viewModel.appSheet = .inboxTools
      }
    }
    
  }
  
  func getOrMakeBundleNamed(_ name: String) async throws -> EmailBundle {
    var bundle = viewModel.bundles.first(where: { $0.name == name })
    
    if bundle == nil {
      let label = try await mailCtrl.createLabel("psymail/\(name)", forAccount: account)
      bundle = EmailBundle(
        name: name, gmailLabelId: label.id, icon: icon, orderIndex: viewModel.bundles.count, context: moc
      )
      try moc.save()
    }
    
    if bundle == nil {
      throw PsyError.unexpectedError(message: "new bundle should exist")
    }
    return bundle!
  }
  
}

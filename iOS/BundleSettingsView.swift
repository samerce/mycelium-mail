import SwiftUI
import SymbolPicker


struct BundleSettingsView: View {
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @State var fetching = false
  @State var iconPickerPresented = false
  @State var icon: String = ""
  @State var filters: [GFilter] = []
  
  var bundle: EmailBundle { sheetCtrl.args[0] as! EmailBundle }
  
  // MARK: - VIEW
  
  var body: some View {
    Group {
      if filters.isEmpty || fetching {
        ProgressView("LOADING FILTERS")
          .controlSize(.large)
          .frame(maxHeight: .infinity)
      } else {
        FilterList
      }
    }
    .sheet(isPresented: $iconPickerPresented) {
      SymbolPicker(symbol: $icon)
        .foregroundColor(.psyAccent)
    }
    .task {
      icon = bundle.icon
      await fetchFilters()
    }
    .safeAreaInset(edge: .top) { Header }
    .safeAreaInset(edge: .bottom) { Toolbar }
  }
  
  var FilterList: some View {
    List(filters, id: \.self) {
      FilterCriteriaRow(criteria: $0.criteria!)
        .listRowSeparator(.hidden)
        .swipeActions {
          Button(role: .destructive) {
            print("deleting criteria")
          } label: {
            Label("trash", systemImage: "trash")
          }
          .tint(.pink)
        }
    }
    .listStyle(.plain)
  }
  
  var Header: some View {
    VStack(spacing: 0) {
      Text("BUNDLE SETTINGS")
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
      
      Divider()
      
      HStack {
        Button {
          iconPickerPresented = true
        } label: {
          SystemImage(name: icon, size: 36, color: .white)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
        
        Button {
        } label: {
          Text(bundle.name)
            .font(.system(size: 27, weight: .black))
            .height(36)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
        .foregroundColor(.white)
      }
      .padding(.vertical, 12)
    }
    .background(OverlayBackgroundView())
  }
  
  var Toolbar: some View {
    HStack(alignment: .lastTextBaseline, spacing: 0) {
      CancelButton
      Spacer()
      AddButton
      Spacer()
      SaveButton
    }
    .padding(.top, 12)
    .padding(.bottom, safeAreaInsets.bottom + 6)
    .padding(.horizontal, 18)
    .background(OverlayBackgroundView())
  }
  
  var buttonWidth = 108.0
  
  var AddButton: some View {
    Button {} label: {
      Text("add filter")
        .font(.system(size: 18))
    }
    .frame(maxWidth: buttonWidth)
    .visible(if: !filters.isEmpty)
  }
  
  var SaveButton: some View {
    Button {
      bundle.icon = icon
      PersistenceController.shared.save()
      sheetCtrl.sheet = .inbox
    } label: {
      Text("save")
        .font(.system(size: 18, weight: .semibold))
    }
    .frame(maxWidth: buttonWidth, alignment: .trailing)
  }
  
  var CancelButton: some View {
    Button {
      sheetCtrl.sheet = .inbox
    } label: {
      Text("cancel")
        .font(.system(size: 18))
    }
    .frame(maxWidth: buttonWidth, alignment: .leading)
  }
  
  func fetchFilters() async {
    let account = AccountController.shared.signedInAccounts.first! // TODO: remove this hack

    do {
      fetching = true
      
      let (filterResponse, _) = try await GmailEndpoint.call(.listFilters, forAccount: account)
      filters = (filterResponse as! GFilterListResponse).filter
      
      filters = filters.filter { filter in
        guard let addLabelIds = filter.action?.addLabelIds
        else { return false }
        return addLabelIds.contains(bundle.labelId)
      }
      
      fetching = false
    }
    catch {
      // TODO: handle error
      print("error fetching gmail filters: \(error.localizedDescription)")
    }
  }
  
}


private struct FilterCriteriaRow: View {
  var criteria: GFilterCriteria
  
  @State var key: String
  @State var value: String
  var prompt: String { cFilterCriteriaById[key]?["prompt"] ?? "" }
  
  init(criteria: GFilterCriteria) {
    self.criteria = criteria
    key = "from" // ?? criteria.to ?? criteria.subject ?? criteria.query ?? criteria.negatedQuery
    value = criteria.from ?? ""
    //?? criteria.hasAttachment ?? criteria.excludeChats ?? criteria.size
  }
  
  var body: some View {
    HStack {
      Picker("", selection: $key) {
        ForEach(cFilterCriteria, id: \.["id"]) {
          Text($0["label"]!).tag($0["id"]!)
            .foregroundColor(.psyAccent)
        }
      }
      .labelsHidden()
      
      TextField("", text: $value, prompt: Text(prompt), axis: .horizontal)
        .textFieldStyle(.roundedBorder)
    }
  }
  
}


let cFilterCriteria = [
  [
    "id": "from",
    "label": "from",
    "prompt": "email or name"
  ],
  [
    "id": "to",
    "label": "to"
  ],
  [
    "id": "subject",
    "label": "subject"
  ],
  [
    "id": "query",
    "label": "search query"
  ],
  [
    "id": "negatedQuery",
    "label": "negated search query"
  ],
  [
    "id": "hasAttachment",
    "label": "has attachment"
  ],
  [
    "id": "size",
    "label": "size"
  ]
]
let cFilterCriteriaById = cFilterCriteria.reduce(into: [:]) { dict, config in
  dict[config["id"]] = config
}

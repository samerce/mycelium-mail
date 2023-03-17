import SwiftUI
import SymbolPicker


struct BundleSettingsView: View {
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @ObservedObject var alertCtrl = AppAlertController.shared
  @State var fetching = false
  @State var iconPickerPresented = false
  @State var icon: String = ""
  @State var filters = [GFilter]()
  @State var criteriaByFilterId = [String:[Criterion]]()
  @State var deletedFilters = Set<GFilter>()
  @State var newFilters = [GFilter]()
  @State var scrollProxy: ScrollViewProxy?
  @State var editMode = EditMode.inactive
  @State var selectedFilters = Set<GFilter>()
  
  var bundle: EmailBundle { sheetCtrl.args[0] as! EmailBundle }
  var validFilters: [GFilter] {
    (newFilters + filters).filter { filter in
      // only return filters that have at least one undeleted criterion
      criteriaByFilterId[filter.id]!.contains(where: { !$0.deleted })
      &&
      !deletedFilters.contains(filter)
    }
  }
  
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
    .environment(\.editMode, $editMode)
  }
  
  var FilterList: some View {
    List(selection: $selectedFilters) {
      Text("FILTERS")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.secondary)
        .listRowBackground(Color.clear)
      
      ForEach(validFilters, id: \.id) { filter in
        FilterListRow(criteria: Binding(
          get: {
            criteriaByFilterId[filter.id]!.filter { !$0.deleted }
          },
          set: { newCriteria in
            criteriaByFilterId[filter.id] = newCriteria
          }
        ))
        .swipeActions {
          Button(role: .destructive) {
            if let index = newFilters.firstIndex(where: { $0.id == filter.id }) {
              newFilters.remove(at: index)
            } else {
              deletedFilters.insert(filter)
            }
          } label: {
            Label("trash", systemImage: "trash")
          }
          .tint(.pink)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(.clear)
    .scrollProxy($scrollProxy)
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
          SystemImage(name: icon, size: 36, color: .white, weight: .semibold)
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
    HStack(spacing: 0) {
      CancelButton
      Spacer()
      
      HStack(spacing: 36) {
        UndoButton
        AddFilterButton
        SelectFiltersButton
      }
      .visible(if: !filters.isEmpty)
      
      Spacer()
      SaveButton
    }
    .padding(.top, 12)
    .padding(.bottom, safeAreaInsets.bottom + 6)
    .padding(.horizontal, 18)
    .background(OverlayBackgroundView())
  }
  
  var buttonWidth = 108.0
  var buttonSize = 20.0
  
  var SelectFiltersButton: some View {
    Button {
      editMode = editMode.isEditing ? .inactive : .active
    } label: {
      ButtonImage(name: "checklist")
    }
  }
  
  var AddFilterButton: some View {
    Button {
      withAnimation {
        scrollProxy?.scrollTo(validFilters.first?.id ?? "")
      }
      Timer.after(0.5) { _ in
        withAnimation {
          let newFilter = GFilter(id: UUID().uuidString)
          newFilters.insert(newFilter, at: 0)
          criteriaByFilterId[newFilter.id] = [
            cCriteriaOptionsById["from"]!.copy()
          ]
        }
      }
    } label: {
      ButtonImage(name: "plus")
    }
  }
  
  var UndoButton: some View {
    Button {
      print("undo")
    } label: {
      ButtonImage(name: "arrow.uturn.backward")
    }
    .contextMenu {
      Button {
        
      } label: {
        Label("redo", systemImage: "arrow.uturn.forward")
      }
    }
  }
  
  var SaveButton: some View {
    Button {
      do {
        try save()
        sheetCtrl.sheet = .inbox
      }
      catch {
        print("failed to save bundle settings: \(error.localizedDescription)")
        // TODO: UX for this error
      }
    } label: {
      Text("save")
        .font(.system(size: 18, weight: .semibold))
        .contentShape(Rectangle())
    }
    .frame(maxWidth: buttonWidth, alignment: .trailing)
  }
  
  var CancelButton: some View {
    Button {
      sheetCtrl.sheet = .inbox
    } label: {
      Text("nope")
        .font(.system(size: 18))
        .contentShape(Rectangle())
    }
    .frame(maxWidth: buttonWidth, alignment: .leading)
  }
  
}


private struct FilterListRow: View {
  @Binding var criteria: [Criterion]
  
  var availableCriteriaOptions: [Criterion] {
    cCriteriaOptions.filter { option in
      !criteria.contains(where: { $0.id == option.id })
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach($criteria, id: \.id) { $criterion in
        CriterionRow(criterion: $criterion)
      }
      
      AddCriterionButton
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 12)
    .padding(.top, 6)
    .background(OverlayBackgroundView(blurStyle: .systemChromeMaterialDark))
    .cornerRadius(12)
    .padding(.horizontal, 9)
    .padding(.vertical, 6)
  }
  
  var AddCriterionButton: some View {
    Menu("add condition") {
      ForEach(availableCriteriaOptions, id: \.id) { option in
        CriteriaOptionButton(optionId: option.id)
      }
    }
    .buttonStyle(.borderless) // prevents row tap from activating the button
  }
  
  func CriteriaOptionButton(optionId: String) -> some View {
    Button(cCriteriaOptionsById[optionId]!.label) {
      let newCriteria = cCriteriaOptionsById[optionId]!.copy()
      criteria.append(newCriteria)
    }
  }
  
}


private struct CriterionRow: View {
  @Binding var criterion: Criterion
  
  var body: some View {
    HStack {
      Text(criterion.label)
        .foregroundColor(.secondary)
      
      TextField("", text: $criterion.value, prompt: Text(criterion.prompt), axis: .horizontal)
      
      Button {
        criterion.deleted = true
      } label: {
        ButtonImage(name: "minus.circle", size: 18)
      }
      .buttonStyle(.borderless) // prevents row tap from activating the button
    }
    .onChange(of: criterion.value) { _ in
      criterion.edited = true
    }
  }
  
}

// MARK: - HELPERS

extension BundleSettingsView {
  
  func fetchFilters() async {
    let account = AccountController.shared.signedInAccounts.first! // TODO: remove this hack

    do {
      fetching = true
      
      let (filterResponse, _) = try await GmailEndpoint.call(.listFilters, forAccount: account)
      filters = (filterResponse as! GFilterListResponse).filter
      
      filters = filters.filter { filter in
        guard let addLabelIds = filter.action?.addLabelIds,
              filter.criteria != nil
        else { return false }
        return addLabelIds.contains(bundle.labelId)
      }
      
      criteriaByFilterId = filters.reduce(into: [:], { dict, filter in
        dict[filter.id] = cCriteriaOptions.reduce(into: []) { array, option in
          if let value = filter.criteria.value(for: option.id) {
            array.append(option.copy(value: value as? String))
          }
        }
      })
      
      fetching = false
    }
    catch {
      // TODO: handle error
      print("error fetching gmail filters: \(error.localizedDescription)")
    }
  }
  
  func save() throws {
    bundle.icon = icon
    PersistenceController.shared.save()
    
    let account = AccountController.shared.accounts.first!.value
    
    for (filterId, criteria) in criteriaByFilterId {
      let filter = filters.first(where: { $0.id == filterId })!
      
      if criteria.allSatisfy({ $0.deleted }) {
        deletedFilters.insert(filter)
        continue
      }
      
      if !criteria.contains(where: { $0.edited }) {
        continue
      }
      
      Task {
        let action = filter.action ?? GFilterAction(addLabelIds: [bundle.labelId])
        
        // TODO: get account from bundle instead of this hack
        try await GmailEndpoint.call(.createFilter, forAccount: account, withBody: [
          "criteria": gCriteriaFromCriteria(criteria),
          "action": action
        ])
        
        // TODO: retry on failure?
        try await GmailEndpoint.call(.deleteFilter(id: filterId), forAccount: account)
        
        alertCtrl.show(message: "bundle settings updated", icon: "checkmark")
      }
    }
    
    for filter in deletedFilters {
      Task {
        try await GmailEndpoint.call(.deleteFilter(id: filter.id), forAccount: account)
      }
    }
  }
  
}


func gCriteriaFromCriteria(_ criteria: [Criterion]) -> GFilterCriteria {
  var gCriteria = GFilterCriteria()
  gCriteria.from = criteria.first(where: { $0.id == "from" })?.value as? String ?? ""
  gCriteria.to = criteria.first(where: { $0.id == "to" })?.value as? String ?? ""
  gCriteria.subject = criteria.first(where: { $0.id == "subject" })?.value as? String ?? ""
  gCriteria.query = criteria.first(where: { $0.id == "query" })?.value as? String ?? ""
  gCriteria.negatedQuery = criteria.first(where: { $0.id == "negatedQuery" })?.value as? String ?? ""
  gCriteria.hasAttachment = false //criteria.first(where: { $0.id == "hasAttachment" })?.value as? Bool ?? false
  gCriteria.excludeChats = true
  gCriteria.size = 0 //criteria.first(where: { $0.id == "size" })?.value as? Int ?? 0
  gCriteria.sizeComparison = criteria.first(where: { $0.id == "sizeComparison" })?.value as? String ?? ""
  return gCriteria
}


// MARK: - DECLARATIONS


let cCriteriaOptions = [
  Criterion(id: "from", value: "", label: "from", prompt: "email or name"),
  Criterion(id: "to", value: "", label: "to", prompt: "email or name"),
  Criterion(id: "subject", value: "", label: "subject", prompt: "subject text"),
  Criterion(id: "query", value: "", label: "search query", prompt: "any text"),
  Criterion(id: "negatedQuery", value: "", label: "negated query", prompt: "text to omit"),
  Criterion(id: "hasAttachment", value: "", label: "has attachment", prompt: "yes or no"),
  Criterion(id: "excludeChats", value: "", label: "exclude chats", prompt: "yes or no"),
  Criterion(id: "size", value: "", label: "size", prompt: "email size"),
  Criterion(id: "sizeComparison", value: "", label: "size comparison", prompt: "bigger or smaller"),
]
let cCriteriaOptionsById = cCriteriaOptions.reduce(into: [:]) { dict, option in
  dict[option.id] = option
}


struct Criterion: Hashable {
  var id: String
  var value: String
  var label: String
  var prompt: String
  var edited: Bool = false
  var deleted = false
  
  func copy(id: String? = nil, value: String? = nil, label: String? = nil, prompt: String? = nil) -> Criterion {
    return Criterion(id: (id ?? self.id).copy() as! String,
                     value: (value ?? self.value).copy() as! String,
                     label: (label ?? self.label).copy() as! String,
                     prompt: (prompt ?? self.prompt).copy() as! String,
                     edited: true,
                     deleted: false)
  }
  
}

import Foundation


extension EmailThread {
  
  func filterIntoBundle(_ bundle: EmailBundle) async throws {
    let address = emails.first!.from.address // TODO: make this more robust
    
    var filterExistsForSameBundle = false
    var filterIdToDelete: String? = nil
    
    let (filterListResponse, _) = try await Gmail.call(.listFilters, forAccount: account)
    let filters = (filterListResponse as! GFilterListResponse).filter
    
    filters.forEach { filter in
      if let addLabelIds = filter.action?.addLabelIds ?? nil,
         let from = filter.criteria?.from ?? nil,
         from.contains(address) {
       
        if addLabelIds.contains(bundle.labelId) {
          filterExistsForSameBundle = true
        } else {
          // filter exists for diff bundle so delete it and create the new filter
          filterIdToDelete = filter.id
        }
      }
    }
    
    if filterExistsForSameBundle {
      print("filter already exists to send \(address) to \(bundle.name), skipping create filter step")
      return
    }
    
    print("creating filter for \(address) to \(bundle.name)")

    /// see:  https://developers.google.com/gmail/api/guides/filter_settings
    let criteria = GFilterCriteria(from: address)
    let action = GFilterAction(addLabelIds: [bundle.labelId], removeLabelIds: ["INBOX", "SPAM"])
    let newFilter = GFilter(id: "", criteria: criteria, action: action)
    let (filter, _) = try await Gmail.call(.createFilter, forAccount: account, withBody: newFilter)
        
    do {
      if let id = filterIdToDelete {
        print("filter already exists to send \(address) to a different bundle; deleting existing filter")
        try await Gmail.call(.deleteFilter(id: id), forAccount: account) // TODO: add retry
      }
    }
    catch {
      print("failed to delete existing filter, undoing changes")
      try await Gmail.call(.deleteFilter(id: (filter as! GFilter).id), forAccount: account)
      throw error
    }
  }
  
  func deleteFilterForBundle(_ bundle: EmailBundle) async throws {
    let (listFiltersResponse, _) = try await Gmail.call(.listFilters, forAccount: account)
    let filters = (listFiltersResponse as! GFilterListResponse).filter
    
    // TODO: make the from address selection more robust
    let fromAddress = emails.first!.from.address
    
    let filterToDelete = filters.first(where: {
      guard let from = $0.criteria?.from,
            let addLabelIds = $0.action?.addLabelIds
      else {
        return false
      }
      return from.contains(fromAddress) && addLabelIds.contains(bundle.labelId)
    })
    
    if let filterToDelete = filterToDelete {
      try await Gmail.call(.deleteFilter(id: filterToDelete.id), forAccount: account)
    }
  }
  
}

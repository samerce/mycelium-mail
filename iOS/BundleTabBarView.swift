import SwiftUI


struct TabRowConfig: Identifiable {
  var label: String
  var icon: String
  var id: String { label }
}


private let RowHeightSmall = 42.0
private let RowHeightBig = 50.0
private let SpacerHeight = 18.0
private let HeaderHeight = 42.0
private let TabRowPadding = 6.0
private let TabRowHPadding = TabRowPadding * 2
private let cTabLimitPerRow = 5


struct BundleTabBarView: View {
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var appSheetCtrl = AppSheetController.shared
  @State var activeTabRow = 0
  
  var selectedBundle: EmailBundle { bundleCtrl.selectedBundle }
  var percentToMid: CGFloat { appSheetCtrl.percentToMid }
  
  var tabRows: [[EmailBundle]] {
    let orderedBundles = bundleCtrl.bundles.sorted(by: { $0.orderIndex < $1.orderIndex })
    var rowIndex = 0
    
    return orderedBundles.reduce(into: [[]]) { tabRows, bundle in
      if tabRows[rowIndex].count >= cTabLimitPerRow {
        rowIndex += 1
        tabRows.append([])
      }
      tabRows[rowIndex].append(bundle)
    }
  }
  
  // MARK: - VIEW
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      ForEach(Array(tabRows.enumerated()), id: \.0) { index, bundles in
        TabRow(index: index, bundles: bundles)
        Spacer().frame(height: SpacerHeight * percentToMid)
      }
    }
    .onAppear {
      activeTabRow = tabRows.firstIndex(where: { tabRow in
        tabRow.contains(where: { $0.name == selectedBundle.name })
      }) ?? 0
    }
  }
  
  
  @ViewBuilder
  private func TabRow(index rowIndex: Int, bundles: [EmailBundle]) -> some View {
    HStack(alignment: .lastTextBaseline) {
      Spacer()
      
      ForEach(Array(bundles.enumerated()), id: \.0) { (bundleIndex, bundle: EmailBundle) in
        TabBarItem(
          iconName: bundle.icon,
          label: bundle.name,
          selected: selectedBundle.name == bundle.name,
          collapsible: activeTabRow != rowIndex,
          unread: bundle.newEmailsSinceLastSeen > 0
        )
        .onTapGesture {
          bundleCtrl.selectedBundle = bundle
          activeTabRow = rowIndex
        }
      }
      
      Spacer()
    }
    .opacity(rowOpacity(rowIndex))
    .height(rowHeight(rowIndex))
    .clipped()
  }
  
  // MARK: - HELPERS
  
  private func rowOpacity(_ index: Int) -> Double {
    return index == activeTabRow ? 1 : Double(percentToMid)
  }
  
  private func rowHeight(_ index: Int) -> CGFloat {
    if index == activeTabRow {
      return RowHeightSmall + ((RowHeightBig - RowHeightSmall) * percentToMid)
    }
    else {
      return max(1, RowHeightBig * percentToMid)
    }
  }
  
//  private var BundleHeader: some View {
//    HStack(spacing: 0) {
//      Text("BUNDLES")
//        .frame(maxHeight: headerHeight, alignment: .leading)
//        .font(.system(size: 14, weight: .light))
//        .foregroundColor(Color(.gray))
//      Spacer()
//      Button(action: onClickBundleSettings) {
//        ZStack {
//          Image(systemName: "gear")
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .foregroundColor(.psyAccent)
//            .font(.system(size: 16, weight: .light))
//        }
//        .frame(width: 20, alignment: .trailing)
//      }
//    }
//    .padding(.horizontal, 18)
//    .padding(.bottom, bottomPadding)
//    .opacity(opacity)
//    .frame(height: headerHeight)
//    .clipped()
//  }
//
//  private func onClickBundleSettings() {
//
//  }
  
}

struct TabBarView_Previews: PreviewProvider {
  static var previews: some View {
    BundleTabBarView()
  }
}

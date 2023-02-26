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
  @EnvironmentObject var viewModel: ViewModel
  @EnvironmentObject var asvm: AppSheetViewModel
  
  var selectedBundle: EmailBundle { viewModel.selectedBundle }
  var percentToMid: CGFloat { asvm.percentToMid }
  
  var tabRows: [[EmailBundle]] {
    var rowIndex = 0
    return viewModel.bundles.reduce(into: [[]]) { tabRows, bundle in
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
          collapsible: rowIndex > 0
        )
        .onTapGesture { viewModel.selectedBundle = bundle }
        .clipped()
      }
      
      Spacer()
    }
    .opacity(rowOpacity(rowIndex))
    .frame(height: rowHeight(rowIndex))
  }
  
  // MARK: - HELPERS
  
  private func rowOpacity(_ index: Int) -> Double {
    if index == 0 { return 1 }
    else {
      return Double(percentToMid)
    }
  }
  
  private func rowHeight(_ index: Int) -> CGFloat {
    if index == 0 {
      return RowHeightSmall + ((RowHeightBig - RowHeightSmall) * percentToMid)
    }
    else {
      return RowHeightBig * percentToMid
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

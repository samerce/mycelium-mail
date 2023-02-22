import SwiftUI


struct TabRow: Identifiable {
  var label: String
  var icon: String
  var id: String { label }
}


private let TabBarHeight = 50.0
private let SpacerHeight = 18.0
private let TranslationMax = 108.0
private let HeaderHeight: CGFloat = 42
private let HeaderBottomPadding: CGFloat = 18
// TODO: store in @AppStorage or EmailBundle
private let tabOrder = ["notifications", "commerce", "inbox", "newsletters", "society", "marketing"]

struct BundleTabBarView: View {
  @EnvironmentObject var viewModel: ViewModel
  @Binding var translationProgress: Double
  
  private var selectedBundle: EmailBundle? {
    viewModel.selectedBundle
  }
  
  private var tabRows: [[EmailBundle]] {
    var rowIndex = 0
    return tabOrder.reduce(into: [[]]) { tabRows, bundleName in
      let bundle = viewModel.bundles.first(where: { $0.name == bundleName })
      if bundle == nil { return }
          
      if tabRows[rowIndex].count >= 5 {
        rowIndex += 1
        tabRows.append([])
      }
      tabRows[rowIndex].append(bundle!)
    }
  }
  
  // MARK: - VIEW
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      ForEach(Array(tabRows.enumerated()), id: \.0) { rowIndex, tabRow in
        let tabRowHeight = heightForTabRow(rowIndex)
        let tabRowOpacity = opacityForTabRow(rowIndex)
        
//        Text(String(tabRow.count))
        
        HStack(alignment: .lastTextBaseline) {
          Spacer()
          
          ForEach(Array(tabRow.enumerated()), id: \.0) { (index, bundle: EmailBundle) in
//            Text(String(item.label))
            TabBarItem(
              iconName: bundle.icon,
              label: bundle.name,
              selected: selectedBundle?.name == bundle.name,
              translationProgress: $translationProgress
            )
            .onTapGesture { viewModel.selectedBundle = bundle }
          }
          
          Spacer()
        }
        .frame(height: 50)
//        .opacity(tabRowOpacity)
        
        Spacer().frame(height: spacerHeight)
      }
    }
    .padding(.top, 50)
  }
  
  private var heightWhileDragging: CGFloat {
    (CGFloat(translationProgress) / appSheetDetents.mid) * HeaderHeight
  }
  private var headerHeight: CGFloat {
    min(HeaderHeight, max(0, heightWhileDragging))
  }
  private var bottomPaddingWhileDragging: CGFloat {
    (CGFloat(translationProgress) / appSheetDetents.mid) * HeaderBottomPadding
  }
  private var bottomPadding: CGFloat {
    min(HeaderBottomPadding, max(0, bottomPaddingWhileDragging))
  }
  private var opacity: CGFloat {
    min(1, max(0, (translationProgress / Double(appSheetDetents.mid)) * 1))
  }
  
  private var BundleHeader: some View {
    HStack(spacing: 0) {
      Text("BUNDLES")
        .frame(maxHeight: headerHeight, alignment: .leading)
        .font(.system(size: 14, weight: .light))
        .foregroundColor(Color(.gray))
      Spacer()
      Button(action: onClickBundleSettings) {
        ZStack {
          Image(systemName: "gear")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.psyAccent)
            .font(.system(size: 16, weight: .light))
        }
        .frame(width: 20, alignment: .trailing)
      }
    }
    .padding(.horizontal, 18)
    .padding(.bottom, bottomPadding)
    .opacity(opacity)
    .frame(height: headerHeight)
    .clipped()
  }
  
  private func onClickBundleSettings() {
    
  }
  
  private func heightForTabRow(_ row: Int) -> CGFloat {
    let heightWhileDragging = (CGFloat(translationProgress) / TranslationMax) * TabBarHeight
    let variableTabBarHeight = min(TabBarHeight, max(0, heightWhileDragging))
    
    return row == rowWithActiveTab ? TabBarHeight : variableTabBarHeight
  }
  
  private func opacityForTabRow(_ row: Int) -> Double {
    let variableOpacity = min(1, max(0, (translationProgress / TranslationMax) * 1))
    return row == rowWithActiveTab ? 1 : variableOpacity
  }
  
  private var spacerHeight: CGFloat {
    min(SpacerHeight, max(0, (CGFloat(translationProgress) / TranslationMax) * SpacerHeight))
  }
  
  private var rowWithActiveTab: Int {
    for (rowIndex, tabRow) in tabRows.enumerated() {
      for bundle in tabRow {
        if bundle.name == selectedBundle?.name {
          return rowIndex
        }
      }
    }
    return -1
  }
  
}

struct TabBarView_Previews: PreviewProvider {
  @State static var translationProgress: Double = 0
  static var previews: some View {
    BundleTabBarView(translationProgress: $translationProgress)
  }
}

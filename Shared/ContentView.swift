import SwiftUI

struct ContentView: View {
#if os(iOS)
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif
  
  var body: some View {
    AppView
      .overlay(alignment: .center) {
        AppAlertView()
      }
  }
  
  @ViewBuilder
  var AppView: some View {
#if os(iOS)
    if horizontalSizeClass == .compact {
      AppCompactView()
    } else {
      AppSplitView()
    }
#else
    AppSplitView()
#endif
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

import SwiftUI

struct ContentView: View {
#if os(iOS)
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif
  
  var body: some View {
    AppView
      .overlay(alignment: .bottom) {
        AppAlertView()
          .safeAreaInset(edge: .bottom) {
            Spacer()
              .frame(height: appSheetDetents.min + safeAreaInsets.bottom + 12)
          }
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

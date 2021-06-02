import SwiftUI

struct ContentView: View {
  #if os(iOS)
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif
  
  var body: some View {
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
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
  }
}

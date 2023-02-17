import SwiftUI

struct AppCompactView: View {
  
  var body: some View {
      InboxView()
  }
  
}

struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
  }
}

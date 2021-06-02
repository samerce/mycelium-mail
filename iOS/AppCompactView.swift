import SwiftUI

struct AppCompactView: View {
  
  var body: some View {
    ZStack {
      EmailListView()
      EmailDetailView()
    }
  }

//  var body: some View {
//    NavigationView {
//      ZStack {
//        EmailListView(selectedTab: $selectedTab)
//        backdropView.opacity(translationProgress)
//      }
//      .dynamicOverlay(overlay)
//      .dynamicOverlayBehavior(behavior)
//      .ignoresSafeArea()
//      .navigationBarTitle(Tabs[selectedTab])
//      .navigationBarItems(
//        leading:
//            Image(systemName: "mail")
//              .resizable()
//              .aspectRatio(contentMode: .fit)
//              .font(.system(size: 27, weight: .light, design: .default))
//              .frame(width: 27, height: 27)
//          .foregroundColor(.pink),
//        trailing:
//            EditButton()
//              .font(.system(size: 17, weight: .regular, design: .default))
//          .foregroundColor(.pink)
//      )
//    }
//    .coordinateSpace(name: "root")
//    .introspectNavigationController { navController in
//      navController.navigationBar.layer.zPosition = 1
//      navController.view.layer.zPosition = 1
//    }
//  }
  
}

struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    let model = MailModel()
    return AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      .environmentObject(model)
  }
}

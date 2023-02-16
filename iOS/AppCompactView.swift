import SwiftUI

private var mailCtrl = MailController.shared

struct AppCompactView: View {
  @StateObject private var model = mailCtrl.model
  @State private var translationProgress = 0.0
  @State private var bundle = "everything"
  @State private var scrollOffsetY: CGFloat = 0
  @State private var safeAreaBackdropOpacity: Double = 0
  @Namespace var headerId
  
  var body: some View {
//    NavigationView {
//      InboxView()
//        .toolbar { TitleToolbar }
//    }
    
    ZStack(alignment: .topTrailing) {
      InboxView()
      EmailDetailView()
    }
    .ignoresSafeArea()
  }
  
  private var TitleToolbar: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text(bundle)
        .font(.system(size: 36, weight: .black))
        .id(headerId)
        .background(GeometryReader {
          Color.clear.preference(key: ViewOffsetKey.self,
                                 value: -$0.frame(in: .global).minY)
        })
        .onPreferenceChange(ViewOffsetKey.self) { scrollOffsetY = $0 }
        .listRowInsets(.init(top: 0, leading: 6, bottom: 9, trailing: 0))
        .listRowSeparator(.hidden)
        .frame(maxWidth: .infinity, maxHeight: 39, alignment: .center)
        .padding(.vertical, 12)
    }
  }
  
}

struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
  }
}

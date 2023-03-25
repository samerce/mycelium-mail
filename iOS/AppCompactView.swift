import SwiftUI


struct AppCompactView: View {
  @ObservedObject var sheetCtrl = AppSheetController.shared
  @State var sheetPresented = true
  
  var body: some View {
    InboxView()
      .sheet(isPresented: $sheetPresented) {
        AppSheetView(sheet: sheetCtrl.sheet)
      }
  }
  
}


struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    AppCompactView()
  }
}

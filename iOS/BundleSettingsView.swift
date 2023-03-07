import SwiftUI
import SymbolPicker


struct BundleSettingsView: View {
  @ObservedObject var bundleCtrl = EmailBundleController.shared
  @ObservedObject var sheetCtrl = AppSheetController.shared
//  static let config = AppSheetConfig(
//    id: "bundle settings",
//    detents: [.height(272)],
//    initialDetent: .height(272)
//  )
  
  @State var conditionType: String = "from"
  @State var conditionValue: String = ""
  @State var iconPickerPresented = false
  @State var icon: String = ""
  
  var bundle: EmailBundle { sheetCtrl.editingBundle! }
  
  // MARK: - VIEW
  
  var body: some View {
    VStack(spacing: 0) {
//      DragSheetIcon()
//        .padding(.top, 6)
//        .padding(.bottom, 12)
      
      VStack(spacing: 0) {
        Text("BUNDLE SETTINGS")
          .font(.system(size: 15))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
        
        Divider()
        
        HStack {
          Button {
            iconPickerPresented = true
          } label: {
            SystemImage(name: icon, size: 36, color: .white)
          }
          .buttonStyle(.bordered)
          .tint(.secondary)
          
          Button {
          } label: {
            Text(bundle.name)
              .font(.system(size: 27, weight: .black))
              .height(36)
          }
          .buttonStyle(.bordered)
          .tint(.secondary)
          .foregroundColor(.white)
        }
        .padding(.vertical, 22)
      }
      
      ScrollView {
        HStack {
          Picker("filters", selection: $conditionType) {
            ForEach(cFilterConditions, id: \.self) {
              Text($0["label"]!).tag($0["id"]!)
                .foregroundColor(.psyAccent)
            }
          }
          
          TextField("", text: $conditionValue, prompt: Text("email or name"), axis: .horizontal)
            .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 9)
        
        Button {
          
        } label: {
          HStack {
            SystemImage(name: "plus", size: 12, color: .white)
            Text("add filter")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
        .foregroundColor(.white)
      }
      
      Spacer()
      
      Button {
        bundle.icon = icon
        sheetCtrl.sheet = .inboxTools
      } label: {
        Text("SAVE")
          .height(27)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .tint(.psyAccent)
      .padding(.bottom, 18)
      
      Button {
        sheetCtrl.sheet = .inboxTools
      } label: {
        VStack(spacing: 0) {
          Text("CANCEL").font(.system(size: 12))
          SystemImage(name: "chevron.compact.down", size: 22, color: .pink)
        }
        .frame(maxWidth: .infinity)
      }
      .tint(.pink)
    }
    .padding(.horizontal, 12)
    .padding(.bottom, safeAreaInsets.bottom)
    .sheet(isPresented: $iconPickerPresented) {
      SymbolPicker(symbol: $icon)
        .foregroundColor(.psyAccent)
    }
    .onAppear {
      icon = bundle.icon
    }
  }
  
}

let cFilterConditions = [
  [
    "id": "from",
    "label": "from"
  ],
  [
    "id": "to",
    "label": "to"
  ],
  [
    "id": "subject",
    "label": "subject"
  ],
  [
    "id": "query",
    "label": "search query"
  ],
  [
    "id": "negatedQuery",
    "label": "negated search query"
  ],
  [
    "id": "hasAttachment",
    "label": "has attachment"
  ],
  [
    "id": "size",
    "label": "size"
  ]
]

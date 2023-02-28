import SwiftUI


struct BundleSettingsView: View {
  @EnvironmentObject var viewModel: ViewModel
//  static let config = AppSheetConfig(
//    id: "bundle settings",
//    detents: [.height(272)],
//    initialDetent: .height(272)
//  )
  
  @State var conditionType: String = "from"
  @State var conditionValue: String = ""
  var bundle: EmailBundle {
    viewModel.selectedBundle
  }
  
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
          } label: {
            SystemImage(name: bundle.icon, size: 36, color: .white)
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
              Text($0).tag($0)
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
        viewModel.appSheet = .inboxTools
      } label: {
        Text("cancel")
          .height(22)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .tint(.pink)
      .padding(.bottom, 12)
      
      Divider()
      
      Button {
        viewModel.appSheet = .inboxTools
      } label: {
        VStack(spacing: 0) {
          Text("save")
            .padding(.bottom, 2)
          SystemImage(name: "chevron.compact.down", size: 27)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
      }
    }
    .padding(.horizontal, 12)
    .padding(.bottom, safeAreaInsets.bottom + safeAreaInsets.top)
  }
  
}

let cFilterConditions = [
  "from", "to", "subject", "query", "negatedQuery", "hasAttachment", "size"
]

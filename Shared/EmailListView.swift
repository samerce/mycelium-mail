import SwiftUI
import DynamicOverlay

private enum Notch: CaseIterable, Equatable {
    case min, mid, max
}

struct EmailListView: View {
  @StateObject var model = MailController.shared.model
  @State private var notch: Notch = .min
  @State var translationProgress = 0.0
  @State var selectedTab = 2
  @State var expandedEmail: Email?
  
  private var perspective: String {
    Tabs[selectedTab]
  }
  private var emails: [Email] {
    model.sortedEmails[perspective] ?? []
  }
  
  var body: some View {
    ScrollView {
      Text(perspective).font(.title)
        .padding(.horizontal, 10)
      
      LazyVStack {
        ForEach(emails, id: \.uuid) { email in
          EmailListRow(email: email)
        }
        .onDelete { _ in print("deleted") }
      }
      .ignoresSafeArea()
      .padding(.horizontal, 10)
      
      Spacer().frame(height: 138)
    }
    .dynamicOverlay(overlay)
    .dynamicOverlayBehavior(behavior)
    .ignoresSafeArea()
  }
  
//  var toolbarHeader: some View {
//    HStack {
//      Image(systemName: "mail")
//        .resizable()
//        .aspectRatio(contentMode: .fit)
//        .font(.system(size: 27, weight: .light, design: .default))
//        .frame(width: 27, height: 27)
//        .foregroundColor(.pink)
//
//      Spacer()
//
//      EditButton()
//        .font(.system(size: 17, weight: .regular, design: .default))
//        .foregroundColor(.pink)
//    }
//    .ignoresSafeArea()
//    .padding(.top, 36)
//    .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterial))
//    .zIndex(1)
//  }
  
  private var backdropView: some View {
    Color.black.opacity(0.54)
  }
  
  private var overlay: some View {
    InboxDrawerView(selectedTab: $selectedTab, translationProgress: $translationProgress)
      .onChange(of: selectedTab) { _ in
        withAnimation {
          notch = .min
        }
      }
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.92)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .fractional(0.19)
      }
    }
    .notchChange($notch)
    .onTranslation { translation in
      withAnimation(.linear(duration: 0.15)) {
        translationProgress = translation.progress
      }
    }
  }
  
}

struct EmailListView_Previews: PreviewProvider {
  static var previews: some View {
    EmailListView()
  }
}


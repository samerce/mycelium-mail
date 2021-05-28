import SwiftUI
import CoreData
import MailCore
import UIKit
import DynamicOverlay

struct AppCompactView: View {
  @State private var notch: Notch = .min
  @State private var isEditing = false
  @State var translationProgress = 0.0
  @State var selectedTab = 2
  
  private enum Notch: CaseIterable, Equatable {
      case min, mid, max
  }

  var body: some View {
    NavigationView {
      ZStack {
//        EmailListView(selectedTab: $selectedTab)
        backdropView.opacity(translationProgress)
      }
      .dynamicOverlay(overlay)
      .dynamicOverlayBehavior(behavior)
      .ignoresSafeArea()
      .navigationBarTitle(Tabs[selectedTab])
      .navigationBarItems(
        leading:
            Image(systemName: "mail")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .font(.system(size: 27, weight: .light, design: .default))
              .frame(width: 27, height: 27)
          .foregroundColor(.pink),
        trailing:
            EditButton()
              .font(.system(size: 17, weight: .regular, design: .default))
          .foregroundColor(.pink)
      )
    }
  }
  
  private var backdropView: some View {
    Color.black.opacity(0.54)
  }
  
  private var overlay: some View {
    InboxDrawerView(selectedTab: $selectedTab, translationProgress: $translationProgress) { event in
      switch event {
      case .didTapTab:
        isEditing = true
        withAnimation { notch = .max }
      }
    }
    .onChange(of: selectedTab) { _ in
      withAnimation {
        notch = .min
      }
    }
    .zIndex(10)
  }
  
  private var behavior: some DynamicOverlayBehavior {
    MagneticNotchOverlayBehavior<Notch> { notch in
      switch notch {
      case .max:
        return .fractional(0.82)
      case .mid:
        return .fractional(0.54)
      case .min:
        return .fractional(0.18)
      }
    }
    .disable(.min, isEditing)
    .notchChange($notch)
    .onTranslation { translation in
      if abs(translationProgress - translation.progress) > 0.15 {
        withAnimation {
          translationProgress = translation.progress
        }
      } else {
        translationProgress = translation.progress
      }
    }
  }
  
  private func showAbout() {
    
  }
  
}

struct AppCompactView_Previews: PreviewProvider {
  static var previews: some View {
    let model = MailModel()
    return AppCompactView()
      .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
      .environmentObject(model)
  }
}

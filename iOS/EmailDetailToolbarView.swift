import SwiftUI

private var mailCtrl = MailController.shared

struct EmailDetailToolbarView: View {
  var email: Email?
  
  @State var expanded = false
  @State var dragAmount: CGFloat = 0
  
  private var emailsFromSender: [Email] {
    mailCtrl.model.emailsFromSenderOf(email!)
  }
  
  var revealGesture: some Gesture {
    DragGesture()
      .onChanged { gesture in
        dragAmount = gesture.translation.height
      }
      .onEnded { gesture in
        let xDist =  abs(gesture.location.x - gesture.startLocation.x)
        let yDist =  abs(gesture.location.y - gesture.startLocation.y)
        let draggedDown = gesture.startLocation.y <  gesture.location.y && yDist > xDist

        if draggedDown && dragAmount > 54 {
          withAnimation { expanded = true }
        }
        
        dragAmount = 0
      }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(email?.fromLine ?? "")
        .font(.system(size: 15, weight: .regular))
      
      Text(email?.subject ?? "")
        .font(.system(size: 18, weight: .medium))
        .opacity((expanded || dragAmount > 0) ? 0 : 1)
        .padding(.bottom, 12)
    }
//    .frame(minWidth: screenWidth, minHeight: safeAreaInsets.top)
//    .padding(.top, safeAreaInsets.top)
//    .edgesIgnoringSafeArea(.top)
//    .contentShape(Rectangle())
    .background(OverlayBackgroundView())
  }
  
//  var EmailHeaderDetails: some View {
//
//  }
  
  func toggleExpanded() {
    withAnimation {
      self.expanded = !self.expanded
    }
  }
  
  private var scrollViewHeight: CGFloat? {
    if dragAmount > 0 {
      return dragAmount
    }
    return expanded ? nil : 0
  }
  
  private var scrollViewOpacity: Double {
    if dragAmount > 0 {
      return Double(dragAmount / UIScreen.main.bounds.height)
    }
    return expanded ? 1 : 0
  }
  
  private var subjectHeight: CGFloat? {
    return (expanded || dragAmount > 0) ? 0 : nil
  }
  
}

struct EmailSenderDrawerView_Previews: PreviewProvider {
  static var previews: some View {
    EmailDetailToolbarView()
  }
}

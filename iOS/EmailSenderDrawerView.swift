import SwiftUI

private var mailCtrl = MailController.shared

struct EmailSenderDrawerView: View {
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
    VStack {
      Spacer().frame(height: 48)
      EmailHeaderDetails
        .padding(.bottom, -9)

      ScrollView {
        LazyVStack {
          ForEach(emailsFromSender, id: \.objectID) { email_ in
            EmailListRow(email: email_)
              .onTapGesture { mailCtrl.selectEmail(email_) }
          }
        }
        Spacer().frame(height: 36)
      }
      .frame(maxHeight: scrollViewHeight)
      .opacity(scrollViewOpacity)
      .padding(0)
      .padding(.top, (expanded || dragAmount > 0) ? 12 : 0)
      .clipped()
    }
    .padding(.horizontal, 20)
    .background(OverlayBackgroundView())
    .onChange(of: email!) { _ in
      withAnimation { self.expanded = false }
    }
    .gesture(revealGesture)
  }
  
  var EmailHeaderDetails: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(email?.fromLine ?? "")
          .font(.system(size: 16, weight: .semibold))
        Spacer()
        Button(action: toggleExpanded) {
          Image(systemName: "chevron.down")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.psyAccent)
            .rotationEffect(expanded ? Angle(degrees: 180) : Angle(degrees: 0))
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
        }
      }
      
      Spacer().frame(height: 4)
      
      Text(email?.subject ?? "")
        .font(.system(size: 16, weight: .light))
        .frame(height: subjectHeight)
        .clipped()
        .opacity((expanded || dragAmount > 0) ? 0 : 1)
        .padding(.bottom, 12)
    }
    .padding(0)
    .contentShape(Rectangle())
    .onTapGesture { self.toggleExpanded() }
  }
  
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
    EmailSenderDrawerView()
  }
}

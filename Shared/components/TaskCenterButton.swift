import Foundation
import SwiftUI


let spring = Animation.spring(dampingFraction: 0.42)
let cDoneImage = "checkmark.circle"
let cBusyImage = "atom"


struct TaskCenterButton: View {
  @ObservedObject var taskCtrl = TaskController.shared
  @State var scale = 1.0
  @State var image = cDoneImage
  
  var busy: Bool { taskCtrl.busy }
  var animation: Animation {
    busy ? .linear(duration: 1).repeatForever(autoreverses: false) : .easeInOut(duration: 1)
  }
  
  var body: some View {
    Button { } label: {
      Group {
        ButtonImage(name: image, size: 18)
          .animation(nil, value: image)
      }
      .rotationEffect(Angle(degrees: busy ? 0 : 360), anchor: .center)
      .scaleEffect(x: scale, y: scale)
      .animation(animation, value: busy)
      .animation(spring, value: scale)
      .onChange(of: busy) { _ in
        scale = 0.0001
        
        Timer.after(0.3) { _ in
          image = busy ? cBusyImage : cDoneImage
          scale = 1.0
        }
      }
    }
  }
  
}

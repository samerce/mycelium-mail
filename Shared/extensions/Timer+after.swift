import Foundation

extension Timer {
  
  @discardableResult
  class func after(
    _ interval: TimeInterval, repeats: Bool? = false, block: @escaping (Timer) -> Void
  ) -> Timer {
    return Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats ?? false, block: block)
  }
  
}

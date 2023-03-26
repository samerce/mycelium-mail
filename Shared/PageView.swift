import SwiftUI

// thanks, phillip!
// https://gist.github.com/phillipcaudell/01beca262f940781a53f64454516d15b
/// A container view that manages navigation between pages of content.
public struct PageView<Content: View, Item: Hashable> {
  
  public typealias ItemProvider = (Item) -> Item?
  public typealias ViewProvider = (Item) -> Content
  
  /// The style for transitions between pages.
  public enum TransitionStyle {
    case scroll
    case pageCurl
  }
  
  @Binding var selection: Item
  let style: TransitionStyle
  let axis: Axis
  let spacing: Int
  let prev: ItemProvider
  let next: ItemProvider
  @Binding var goToPage: (Item) -> Void
  @ViewBuilder let content: (Item) -> Content
  
  public init(selection: Binding<Item>, style: TransitionStyle = .scroll, axis: Axis = .horizontal, spacing: Int = 10, prev: @escaping ItemProvider, next: @escaping ItemProvider, goToPage: Binding<(Item) -> Void>, @ViewBuilder content: @escaping ViewProvider) {
    _selection = selection
    self.style = style
    self.axis = axis
    self.spacing = spacing
    self.prev = prev
    self.next = next
    self.content = content
    self._goToPage = goToPage
  }
}

extension PageView: UIViewControllerRepresentable {
  
  public typealias UIViewControllerType = UIPageViewController
  
  public func makeUIViewController(context: Context) -> UIPageViewController {
    let viewController = UIPageViewController(
      transitionStyle: style.uiPageViewController,
      navigationOrientation: axis.uiPageViewController,
      options: [.interPageSpacing: spacing]
    )
    viewController.delegate = context.coordinator
    viewController.dataSource = context.coordinator
    let initialView = ItemHostingController(item: selection, view: content(selection))
    viewController.setViewControllers([initialView], direction: .forward, animated: false)
    
    goToPage = { item in
      DispatchQueue.main.async {
        // forces controller to reload its data
        viewController.dataSource = nil
        viewController.dataSource = context.coordinator
        
        let itemViewController = ItemHostingController(item: item, view: content(item))
        viewController.setViewControllers([itemViewController], direction: .forward, animated: false)
        
        selection = item
      }
    }
    
    return viewController
  }
  
  public func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
    let isAnimated = context.transaction.animation != nil
    goTo(selection, pageViewController: uiViewController, animated: isAnimated)
  }
  
  // MARK: - Navigation
  
  func goTo(_ item: Item, pageViewController: UIPageViewController, animated: Bool = true) {
    guard let currentViewController = pageViewController.viewControllers?.first as? ItemHostingController<Item> else {
      return
    }
    guard currentViewController.item != item else {
      return
    }
    let viewController = ItemHostingController(item: item, view: content(item))
    pageViewController.setViewControllers([viewController], direction: .forward, animated: animated)
  }
  
  // MARK: - Coordinator
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  public class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    let pageView: PageView
    
    init(_ pageView: PageView) {
      self.pageView = pageView
    }
    
    // MARK: - Data Source
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
      guard let viewController = viewController as? ItemHostingController<Item> else {
        return nil
      }
      if let prev = pageView.prev(viewController.item) {
        return makeView(prev)
      } else {
        return nil
      }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
      guard let viewController = viewController as? ItemHostingController<Item> else {
        return nil
      }
      if let next = pageView.next(viewController.item) {
        print("Requesting item after \(viewController.item)")
        return makeView(next)
      } else {
        print("Nothing after \(viewController.item)")
        return nil
      }
    }
    
    // MARK: - Delegate
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
      guard let viewController = pageViewController.viewControllers?.first as? ItemHostingController<Item> else {
        return
      }
      let item = viewController.item
      if pageView.selection != item {
        pageView.selection = item
      }
    }
    
    // MARK: - Helpers
    
    func makeView(_ item: Item) -> PageView.ItemHostingController<Item> {
      ItemHostingController(item: item, view: pageView.content(item))
    }
  }
  
  class ItemHostingController<Item>: UIHostingController<Content> {
    let item: Item
    
    init(item: Item, view: Content) {
      self.item = item
      super.init(rootView: view)
      self.view.backgroundColor = .clear
      self.view.isOpaque = false
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }
}

extension PageView.TransitionStyle {
  var uiPageViewController: UIPageViewController.TransitionStyle {
    switch self {
      case .scroll:
        return .scroll
      case .pageCurl:
        return .pageCurl
    }
  }
}

extension Axis {
  var uiPageViewController: UIPageViewController.NavigationOrientation {
    switch self {
      case .horizontal:
        return .horizontal
      case .vertical:
        return .vertical
    }
  }
}

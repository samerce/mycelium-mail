import SwiftUI

private let Filters = [
  "today": "sun.max",
  "last week": "calendar.badge.clock",
  "unread": "envelope",
  "read": "envelope.open",
  "starred": "star.fill",
  "contacts": "rectangle.stack.person.crop",
  "vip": "person.crop.circle.badge.exclamationmark",
  "attachments": "paperclip",
  "tickets": "wallet.pass"
]

private let FilterImageSize: CGFloat = 36
private var filterGridItems: [GridItem] {
  Array(repeating: .init(.flexible(minimum: 54, maximum: .infinity)), count: 3)
}

struct FilterView: View {
  var body: some View {
    LazyVGrid(columns: filterGridItems, spacing: 12) {
      ForEach(Array(Filters.keys), id: \.self) { filter in
        Button(action: {}) {
          VStack(spacing: 9) {
            Image(systemName: Filters[filter] ?? "")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: FilterImageSize, height: FilterImageSize)
              .font(.system(size: FilterImageSize, weight: .light))
              .contentShape(Rectangle())
            
            Text(filter)
              .font(.system(size: 13))
          }
          .frame(maxWidth: .infinity, maxHeight: 108)
          .padding(18)
          .background(Color(.tertiarySystemBackground))
          .cornerRadius(9)
          .shadow(radius: 6)
          .foregroundColor(Color(.secondaryLabel))
        }
      }
    }
  }
}

struct FilterView_Previews: PreviewProvider {
  static var previews: some View {
    FilterView()
  }
}

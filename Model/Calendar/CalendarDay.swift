import Foundation

struct CalendarDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let dayNumberText: String
    let weekdayShortText: String
}


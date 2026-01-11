import Foundation

enum WeekCalendarProvider {

    static func makeWeekStartingToday(from date: Date = Date(), calendar: Calendar = .current) -> [CalendarDay] {
        let start = calendar.startOfDay(for: date)

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "d"

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.calendar = calendar
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.dateFormat = "EEE"

        return (0..<7).compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return CalendarDay(
                date: d,
                dayNumberText: dayFormatter.string(from: d),
                weekdayShortText: weekdayFormatter.string(from: d)
            )
        }
    }

    static func weekTitle(from date: Date = Date(), calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start

        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM"

        return "\(f.string(from: start)) - \(f.string(from: end))"
    }

    static func indexOfToday(in days: [CalendarDay], calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: Date())
        return days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) ?? 0
    }
}


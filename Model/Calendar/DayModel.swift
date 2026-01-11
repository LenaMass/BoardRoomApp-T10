import Foundation

struct DayModel: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let day: String
    let weekDay: String
}

enum DayBuilder {

    static func weekStartingToday(from date: Date = Date(), calendar: Calendar) -> [DayModel] {
        let start = calendar.startOfDay(for: date)

        let fd = DateFormatter()
        fd.calendar = calendar
        fd.locale = Locale(identifier: "en_US_POSIX")
        fd.timeZone = .current
        fd.dateFormat = "d"

        let fw = DateFormatter()
        fw.calendar = calendar
        fw.locale = Locale(identifier: "en_US_POSIX")
        fw.timeZone = .current
        fw.dateFormat = "EEE"

        return (0..<7).compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DayModel(date: d, day: fd.string(from: d), weekDay: fw.string(from: d))
        }
    }

    static func weekTitle(from date: Date = Date(), calendar: Calendar) -> String {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start

        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "d MMM"

        return "\(f.string(from: start)) - \(f.string(from: end))"
    }

    static func indexOfToday(in days: [DayModel], calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: Date())
        return days.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) ?? 0
    }
}


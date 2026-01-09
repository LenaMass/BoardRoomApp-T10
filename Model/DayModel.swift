import Foundation



//possible calen

struct DayModel: Identifiable {
    let id = UUID()
    let date: Date
    let day: String
    let weekDay: String
}

enum DayBuilder {
    static func days(inMonthOf date: Date, calendar: Calendar) -> [DayModel] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<2

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

        return range.compactMap { day in
            guard let d = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return DayModel(date: d, day: fd.string(from: d), weekDay: fw.string(from: d))
        }
    }

    static func monthTitle(for date: Date, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "MMMM"
        return f.string(from: date)
    }
}

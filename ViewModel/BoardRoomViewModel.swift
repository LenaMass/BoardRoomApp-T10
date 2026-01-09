import SwiftUI
import Combine

@MainActor
final class BoardRoomsViewModel: ObservableObject {

    // Persisted user info (you used this in the View)
    @AppStorage("employeeID") private var employeeID: String = ""

    // UI State
    @Published var boardrooms: [BoardroomRecord] = []
    @Published var bookings: [BookingData] = []
    @Published var selectedDayIndex: Int = 0
    @Published var bookingsError: String = ""
    @Published var isLoadingBookings: Bool = false

    let calendar = BoardroomsAPI.gregorianCalendar

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    var days: [DayModel] {
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let range = calendar.range(of: .day, in: .month, for: today) ?? 1..<2

        let formatterDay = DateFormatter()
        formatterDay.calendar = calendar
        formatterDay.dateFormat = "d"

        let formatterWeekday = DateFormatter()
        formatterWeekday.calendar = calendar
        formatterWeekday.dateFormat = "EEE"

        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return DayModel(date: date, day: formatterDay.string(from: date), weekDay: formatterWeekday.string(from: date))
        }
    }

    var todayIndexInMonth: Int {
        let day = calendar.component(.day, from: Date())
        return max(0, min(day - 1, days.count - 1))
    }

    var selectedDate: Date {
        guard days.indices.contains(selectedDayIndex) else { return Date() }
        return days[selectedDayIndex].date
    }

    var apiRooms: [RoomInfo] {
        boardrooms.compactMap { rec in
            guard let f = rec.fields, let title = f.name, !title.isEmpty else { return nil }
            return RoomInfo(
                title: title,
                floor: "Floor \(f.floorNo ?? 0)",
                people: "\(f.seatNo ?? 0)",
                imageName: "room1",
                imageURL: f.imageURL,
                features: mapFacilitiesToFeatures(f.facilities ?? []),
                description: f.description ?? ""
            )
        }
    }

    var validBookings: [BookingData] {
        bookings.filter {
            ($0.fields.boardroomID ?? "").isEmpty == false &&
            $0.fields.date != nil
        }
    }

    var myBookings: [BookingData] {
        validBookings.filter { ($0.fields.employeeID ?? "") == employeeID }
    }

    var nextMyBooking: BookingData? {
        let todayInt = BoardroomsAPI.dateInt(from: Date())
        return myBookings
            .filter { ($0.fields.date ?? 0) >= todayInt }
            .sorted { ($0.fields.date ?? 0) < ($1.fields.date ?? 0) }
            .first
    }

    func bookingsCountThisMonth() -> Int {
        let y = calendar.component(.year, from: Date())
        let m = calendar.component(.month, from: Date())
        return validBookings.filter {
            let date = $0.fields.date ?? 0
            return date / 10000 == y && (date / 100) % 100 == m
        }.count
    }

    func isRoomUnavailable(_ room: RoomInfo, on date: Date) -> Bool {
        BoardroomsAPI.isRoomBooked(
            roomTitle: room.title,
            bookings: validBookings,
            boardrooms: boardrooms,
            on: date
        )
    }

    func roomInfo(for booking: BookingData) -> RoomInfo? {
        guard let roomID = booking.fields.boardroomID,
              let rec = boardrooms.first(where: { $0.id == roomID }),
              let f = rec.fields,
              let title = f.name else { return nil }

        return RoomInfo(
            title: title,
            floor: "Floor \(f.floorNo ?? 0)",
            people: "\(f.seatNo ?? 0)",
            imageName: "room1",
            imageURL: f.imageURL,
            features: mapFacilitiesToFeatures(f.facilities ?? []),
            description: f.description ?? ""
        )
    }

    func bootstrap() async {
        selectedDayIndex = todayIndexInMonth
        await fetchData()
    }

    func fetchData() async {
        isLoadingBookings = true
        bookingsError = ""

        do {
            let result = try await BoardroomsAPI.fetchData()
            bookings = result.bookings
            boardrooms = result.boardrooms
        } catch {
            bookingsError = error.localizedDescription
        }

        isLoadingBookings = false
    }

    private func mapFacilitiesToFeatures(_ facilities: [String]) -> [RoomFeature] {
        let lower = facilities.map { $0.lowercased() }
        var out: [RoomFeature] = []
        if lower.contains(where: { $0.contains("wifi") }) { out.append(.wifi) }
        if lower.contains(where: { $0.contains("screen") || $0.contains("display") || $0.contains("tv") }) { out.append(.screen) }
        if lower.contains(where: { $0.contains("mic") }) { out.append(.mic) }
        if lower.contains(where: { $0.contains("control") || $0.contains("controller") }) { out.append(.control) }
        return out
    }
}

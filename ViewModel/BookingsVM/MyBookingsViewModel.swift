import Foundation
import Combine


//for the edit bookings and deletes 

@MainActor
final class MyBookingsViewModel: ObservableObject {
    struct DisplayBooking: Identifiable, Hashable {
        let id: String
        let booking: BookingData
        let dateInt: Int
        let dateText: String
        let roomID: String
    }

    @Published private(set) var bookings: [BookingData] = []
    private(set) var boardrooms: [BoardroomRecord] = []

    @Published var busyIDs: Set<String> = []
    @Published var errorText: String = ""

    @Published var editingBooking: BookingData?
    @Published var editDayIndex: Int = 0

    private let onChanged: (() async -> Void)?
    private let service: BookingsServicing
    private let calendar: Calendar = BoardroomsAPI.gregorianCalendar

    init(bookings: [BookingData], boardrooms: [BoardroomRecord], onChanged: (() async -> Void)?, service: BookingsServicing) {
        self.bookings = bookings
        self.boardrooms = boardrooms
        self.onChanged = onChanged
        self.service = service
    }

    func setData(bookings: [BookingData], boardrooms: [BoardroomRecord]) {
        self.bookings = bookings
        self.boardrooms = boardrooms
    }

    var monthTitle: String {
        DayBuilder.monthTitle(for: Date(), calendar: calendar)
    }

    var days: [DayModel] {
        DayBuilder.days(inMonthOf: Date(), calendar: calendar)
    }

    var displayBookings: [DisplayBooking] {
        bookings.compactMap { booking in
            guard let dateInt = booking.fields.date else { return nil }
            guard let roomID = booking.fields.boardroomID, !roomID.isEmpty else { return nil }
            return DisplayBooking(
                id: booking.id,
                booking: booking,
                dateInt: dateInt,
                dateText: BoardroomsAPI.shortDateText(from: dateInt),
                roomID: roomID
            )
        }
        .sorted { $0.dateInt < $1.dateInt }
    }

    func startEdit(booking: BookingData) {
        errorText = ""
        if let di = booking.fields.date,
           let d = BoardroomsAPI.dateFromInt(di) {
            let day = calendar.component(.day, from: d)
            editDayIndex = max(0, min(day - 1, days.count - 1))
        } else {
            editDayIndex = 0
        }
        editingBooking = booking
    }

    func saveEditedDate(for booking: BookingData) async {
        errorText = ""
        busyIDs.insert(booking.id)
        defer { busyIDs.remove(booking.id) }

        guard let roomID = booking.fields.boardroomID, !roomID.isEmpty else {
            errorText = "Missing boardroom id"
            return
        }
        guard let employeeID = booking.fields.employeeID, !employeeID.isEmpty else {
            errorText = "Missing employee id"
            return
        }
        guard days.indices.contains(editDayIndex) else {
            errorText = "Invalid day"
            return
        }

        let selected = days[editDayIndex].date
        let newDateInt = BoardroomsAPI.dateInt(from: selected)
        let status = booking.fields.status ?? "Confirmed"

        do {
            _ = try await service.updateBookingPUT(
                id: booking.id,
                status: status,
                employeeID: employeeID,
                boardroomID: roomID,
                date: newDateInt
            )
            editingBooking = nil
            if let onChanged { await onChanged() }
        } catch {
            errorText = error.localizedDescription
        }
    }

    func deleteBooking(_ booking: BookingData) async {
        errorText = ""
        busyIDs.insert(booking.id)
        defer { busyIDs.remove(booking.id) }

        do {
            let ok = try await service.deleteBooking(id: booking.id)
            if ok == false { errorText = "Delete failed" }
            if let onChanged { await onChanged() }
        } catch {
            errorText = error.localizedDescription
        }
    }
}


import Foundation
import Combine


//for fetching and del

@MainActor
final class RoomDetailViewModel: ObservableObject {

    let room: RoomInfo
    let initialDate: Date
    private let service: BookingsServicing

    @Published var selectedDayIndex: Int = 0
    @Published private(set) var boardrooms: [BoardroomRecord] = []
    @Published private(set) var bookings: [BookingData] = []

    @Published var errorText: String = ""
    @Published var isLoading: Bool = false

    @Published var showSuccess: Bool = false
    @Published var successDate: Date = Date()

    private let calendar: Calendar = .current

    init(room: RoomInfo, initialDate: Date, service: BookingsServicing? = nil) {
        self.room = room
        self.initialDate = initialDate
        self.service = service ?? BookingsService()
    }

    var monthTitle: String {
        DayBuilder.weekTitle(from: Date(), calendar: calendar)
    }

    var days: [DayModel] {
        DayBuilder.weekStartingToday(from: Date(), calendar: calendar)
    }

    var selectedDate: Date {
        guard days.indices.contains(selectedDayIndex) else { return Date() }
        return days[selectedDayIndex].date
    }

    var roomRecordID: String? {
        BoardroomsAPI.boardroomRecordID(for: room.title, in: boardrooms)
    }

    var isUnavailableSelectedDay: Bool {
        BoardroomsAPI.isRoomBooked(
            roomTitle: room.title,
            bookings: bookings,
            boardrooms: boardrooms,
            on: selectedDate
        )
    }

    func onAppearLoad() async {
        selectedDayIndex = 0
        await fetchData()
    }

    func fetchData() async {
        isLoading = true
        errorText = ""
        do {
            let result = try await BoardroomsAPI.fetchData()
            bookings = result.bookings
            boardrooms = result.boardrooms
        } catch {
            errorText = "Failed to load data"
        }
        isLoading = false
    }

    func bookSelectedDay(employeeID: String) async {
        errorText = ""
        guard !employeeID.isEmpty else {
            errorText = "Employee not logged in"
            return
        }
        guard let boardroomID = roomRecordID else {
            errorText = "Missing boardroom id"
            return
        }

        let di = BoardroomsAPI.dateInt(from: selectedDate)

        do {
            _ = try await service.createBooking(
                status: "Confirmed",
                employeeID: employeeID,
                boardroomID: boardroomID,
                date: di
            )
            successDate = selectedDate
            showSuccess = true
            await fetchData()
        } catch {
            errorText = error.localizedDescription
        }
    }
}


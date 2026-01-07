import Foundation

struct BoardroomsResponse: Decodable {
    let records: [BoardroomRecord]
}

struct BoardroomRecord: Decodable, Identifiable {
    let id: String
    let createdTime: String?
    let fields: BoardroomFields?
}

struct BoardroomFields: Decodable {
    let name: String?
    let floorNo: Int?
    let seatNo: Int?
    let description: String?
    let facilities: [String]?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case floorNo = "floor_no"
        case seatNo = "seat_no"
        case description
        case facilities
        case imageURL = "image_url"
    }
}

enum BoardroomsAPIError: Error {
    case invalidURL
    case invalidResponse
    case missingAPIToken
}

enum BoardroomsAPI {

    static let gregorianCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal
    }()

    static func getAllBoardrooms() async throws -> [BoardroomRecord] {
        let apiToken = try loadToken()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/boardrooms"

        guard let url = components.url else { throw BoardroomsAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BoardroomsAPIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(BoardroomsResponse.self, from: data)
        return decoded.records
    }

    static func fetchData() async throws -> (bookings: [BookingData], boardrooms: [BoardroomRecord]) {
        async let bookings = BookingData.getAllBookings()
        async let boardrooms = getAllBoardrooms()
        return try await (bookings: bookings, boardrooms: boardrooms)
    }

    static func boardroomRecordID(for roomTitle: String, in boardrooms: [BoardroomRecord]) -> String? {
        boardrooms.first { ($0.fields?.name ?? "") == roomTitle }?.id
    }

    static func boardroomName(for roomID: String, in boardrooms: [BoardroomRecord]) -> String? {
        boardrooms.first(where: { $0.id == roomID })?.fields?.name
    }
    
    
//Change Calendar func later (old approach)
    
    static func dateInt(from date: Date) -> Int {
        let d = gregorianCalendar.startOfDay(for: date)
        let c = gregorianCalendar.dateComponents([.year, .month, .day], from: d)
        let y = c.year ?? 0
        let m = c.month ?? 0
        let day = c.day ?? 0
        return y * 10000 + m * 100 + day
    }

    static func dateFromInt(_ di: Int) -> Date? {
        let y = di / 10000
        let m = (di / 100) % 100
        let d = di % 100
        return gregorianCalendar.date(from: DateComponents(year: y, month: m, day: d))
    }

    static func shortDateText(from dateInt: Int) -> String {
        guard let d = dateFromInt(dateInt) else { return "—" }
        return shortDateText(from: d)
    }

    static func shortDateText(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    static func isRoomBooked(roomTitle: String, bookings: [BookingData], boardrooms: [BoardroomRecord], on date: Date) -> Bool {
        guard let roomID = boardroomRecordID(for: roomTitle, in: boardrooms) else { return false }
        let di = dateInt(from: date)

        return bookings.contains { b in
            guard let bid = b.fields.boardroomID, let bdi = b.fields.date else { return false }
            return bid == roomID && bdi == di
        }
    }

    private static func loadToken() throws -> String {
        guard let apiToken = Bundle.main.infoDictionary?["APIToken"] as? String,
              !apiToken.isEmpty,
              !apiToken.contains("$(") else {
            throw BoardroomsAPIError.missingAPIToken
        }
        return apiToken
    }
}


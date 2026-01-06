import Foundation

struct BoardroomsResponse: Decodable {
    let records: [BoardroomRecord]
}

struct BoardroomRecord: Decodable, Identifiable {
    let id: String
    let createdTime: String?
    let fields: BoardroomFields?
}

struct AirtableAttachment: Decodable {
    let url: String?
}

struct BoardroomFields: Decodable {
    let name: String?
    let floorNo: Int?
    let seatNo: Int?
    let description: String?
    let facilities: [String]?
    let imageURL: String?

    private enum CodingKeys: String, CodingKey {
        case floorNo = "floor_no"
        case seatNo = "seat_no"
        case description
        case facilities
        case imageURL = "image_url"
    }

    private enum NameKeys: String, CodingKey {
        case name
        case Name
    }

    private enum ImagesKeys: String, CodingKey {
        case Images
        case images
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let nc = try decoder.container(keyedBy: NameKeys.self)
        let ic = try decoder.container(keyedBy: ImagesKeys.self)

        if let v = try? nc.decodeIfPresent(String.self, forKey: .name) {
            name = v
        } else {
            name = try? nc.decodeIfPresent(String.self, forKey: .Name)
        }

        floorNo = try c.decodeIfPresent(Int.self, forKey: .floorNo)
        seatNo = try c.decodeIfPresent(Int.self, forKey: .seatNo)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        facilities = try c.decodeIfPresent([String].self, forKey: .facilities)

        if let direct = try c.decodeIfPresent(String.self, forKey: .imageURL),
           !direct.isEmpty {
            imageURL = direct
            return
        }

        if let atts = (try? ic.decodeIfPresent([AirtableAttachment].self, forKey: .Images))
            ?? (try? ic.decodeIfPresent([AirtableAttachment].self, forKey: .images)),
           let first = atts.first?.url,
           !first.isEmpty {
            imageURL = first
        } else {
            imageURL = nil
        }
    }
}

enum BoardroomsAPIError: Error {
    case invalidURL
    case invalidResponse
    case missingAPIToken
}

enum BoardroomsAPI {

    static func isRoomBooked(
        roomTitle: String,
        bookings: [BookingData],
        boardrooms: [BoardroomRecord],
        on date: Date
    ) -> Bool {
        let dateInt = dateInt(from: date)
        guard let roomID = boardroomRecordID(for: roomTitle, in: boardrooms) else { return false }
        return bookings.contains { ($0.fields.boardroomID ?? "") == roomID && ($0.fields.date ?? -1) == dateInt }
    }

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

    static func isRoomBooked(roomTitle: String, bookings: [BookingData], boardrooms: [BoardroomRecord]) -> Bool {
        guard let roomID = boardroomRecordID(for: roomTitle, in: boardrooms) else { return false }
        return bookings.contains { $0.fields.boardroomID == roomID }
    }

    static func boardroomName(for roomID: String, in boardrooms: [BoardroomRecord]) -> String? {
        boardrooms.first { $0.id == roomID }?.fields?.name
    }

    static let gregorianCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        return cal
    }()

    static func dateInt(from date: Date) -> Int {
        let cal = gregorianCalendar
        let d0 = cal.startOfDay(for: date)
        let y = cal.component(.year, from: d0)
        let m = cal.component(.month, from: d0)
        let d = cal.component(.day, from: d0)
        return (y * 10000) + (m * 100) + d
    }

    static func dateFromInt(_ yyyymmdd: Int) -> Date? {
        let y = yyyymmdd / 10000
        let m = (yyyymmdd / 100) % 100
        let d = yyyymmdd % 100
        return gregorianCalendar.date(from: DateComponents(year: y, month: m, day: d))
    }

    static func shortDateText(from yyyymmdd: Int) -> String {
        guard let date = dateFromInt(yyyymmdd) else { return "" }
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    static func monthBounds(for date: Date) -> (start: Date, end: Date) {
        let start = gregorianCalendar.date(from: gregorianCalendar.dateComponents([.year, .month], from: date)) ?? date
        let range = gregorianCalendar.range(of: .day, in: .month, for: date) ?? 1..<2
        let days = max(1, range.count)
        let end = gregorianCalendar.date(byAdding: .day, value: days - 1, to: start) ?? start
        return (start, end)
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


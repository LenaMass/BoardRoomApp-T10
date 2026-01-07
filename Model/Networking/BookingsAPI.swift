import Foundation

struct BookingData: Codable, Identifiable {
    let id: String
    let createdTime: String
    let fields: BookingFields

    struct BookingFields: Codable, Hashable {
        let status: String?
        let employeeID: String?
        let boardroomID: String?
        let date: Int?

        enum CodingKeys: String, CodingKey {
            case status
            case employeeID = "employee_id"
            case boardroomID = "boardroom_id"
            case date
        }
    }

    enum BookingError: Error, LocalizedError {
        case invalidURL
        case invalidResponse(statusCode: Int, message: String)
        case invalidData
        case missingAPIToken

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse(let code, let message):
                return "Airtable request failed (\(code)): \(message)"
            case .invalidData:
                return "Invalid response data"
            case .missingAPIToken:
                return "Missing APIToken in Info.plist"
            }
        }
    }

    struct AirtableResponse: Codable {
        let records: [BookingData]
    }

    private struct AirtableErrorResponse: Codable {
        let error: AirtableError
        struct AirtableError: Codable {
            let type: String
            let message: String
        }
    }

    private struct CreateBookingRequest: Codable {
        let records: [CreateRecord]
        struct CreateRecord: Codable { let fields: CreateFields }
    }

    private struct CreateFields: Codable {
        let status: String
        let employeeID: String
        let boardroomID: String
        let date: Int

        enum CodingKeys: String, CodingKey {
            case status
            case employeeID = "employee_id"
            case boardroomID = "boardroom_id"
            case date
        }
    }

    private struct UpdateBookingRequest: Codable {
        let records: [UpdateRecord]
        struct UpdateRecord: Codable {
            let id: String
            let fields: UpdateFields
        }
    }

    private struct UpdateFields: Codable {
        let status: String
        let employeeID: String
        let boardroomID: String
        let date: Int

        enum CodingKeys: String, CodingKey {
            case status
            case employeeID = "employee_id"
            case boardroomID = "boardroom_id"
            case date
        }
    }

    private struct DeleteResponse: Codable {
        let records: [DeletedRecord]
        struct DeletedRecord: Codable {
            let id: String
            let deleted: Bool
        }
    }

    static func getAllBookings() async throws -> [BookingData] {
        let apiToken = try loadToken()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/bookings"

        guard let url = components.url else { throw BookingError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BookingError.invalidResponse(statusCode: -1, message: "No HTTP response")
        }

        guard http.statusCode == 200 else {
            throw BookingError.invalidResponse(
                statusCode: http.statusCode,
                message: parseAirtableErrorMessage(from: data)
            )
        }

        let decoded = try JSONDecoder().decode(AirtableResponse.self, from: data)
        return decoded.records
    }

    static func createBooking(
        status: String = "Confirmed",
        employeeID: String,
        boardroomID: String,
        date: Int
    ) async throws -> BookingData {

        let apiToken = try loadToken()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/bookings"

        guard let url = components.url else { throw BookingError.invalidURL }

        let fields = CreateFields(
            status: status,
            employeeID: employeeID,
            boardroomID: boardroomID,
            date: date
        )

        let body = CreateBookingRequest(records: [.init(fields: fields)])
        let jsonData = try JSONEncoder().encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BookingError.invalidResponse(statusCode: -1, message: "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            throw BookingError.invalidResponse(
                statusCode: http.statusCode,
                message: parseAirtableErrorMessage(from: data)
            )
        }

        let decoded = try JSONDecoder().decode(AirtableResponse.self, from: data)
        guard let created = decoded.records.first else { throw BookingError.invalidData }
        return created
    }

    static func updateBookingPUT(
        id: String,
        status: String,
        employeeID: String,
        boardroomID: String,
        date: Int
    ) async throws -> BookingData {

        let apiToken = try loadToken()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/bookings"

        guard let url = components.url else { throw BookingError.invalidURL }

        let fields = UpdateFields(
            status: status,
            employeeID: employeeID,
            boardroomID: boardroomID,
            date: date
        )

        let body = UpdateBookingRequest(records: [.init(id: id, fields: fields)])
        let jsonData = try JSONEncoder().encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BookingError.invalidResponse(statusCode: -1, message: "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            throw BookingError.invalidResponse(
                statusCode: http.statusCode,
                message: parseAirtableErrorMessage(from: data)
            )
        }

        let decoded = try JSONDecoder().decode(AirtableResponse.self, from: data)
        guard let updated = decoded.records.first else { throw BookingError.invalidData }
        return updated
    }

    static func deleteBooking(id: String) async throws -> Bool {
        let apiToken = try loadToken()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/bookings"
        components.queryItems = [URLQueryItem(name: "records[]", value: id)]

        guard let url = components.url else { throw BookingError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw BookingError.invalidResponse(statusCode: -1, message: "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            throw BookingError.invalidResponse(
                statusCode: http.statusCode,
                message: parseAirtableErrorMessage(from: data)
            )
        }

        let decoded = try JSONDecoder().decode(DeleteResponse.self, from: data)
        return decoded.records.first?.deleted == true
    }

    private static func parseAirtableErrorMessage(from data: Data) -> String {
        if let err = try? JSONDecoder().decode(AirtableErrorResponse.self, from: data) {
            return "\(err.error.type): \(err.error.message)"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }

    private static func loadToken() throws -> String {
        guard let apiToken = Bundle.main.infoDictionary?["APIToken"] as? String,
              !apiToken.isEmpty,
              !apiToken.contains("$(") else {
            throw BookingError.missingAPIToken
        }
        return apiToken
    }
}


import Foundation

enum BookingsServiceError: Error, LocalizedError {
    case invalidURL
    case missingAPIToken
    case invalidResponse(statusCode: Int, message: String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .missingAPIToken:
            return "Missing APIToken in Info.plist"
        case .invalidResponse(let code, let message):
            return "Airtable request failed (\(code)): \(message)"
        case .invalidData:
            return "Invalid response data"
        }
    }
}

protocol BookingsServicing {
    func getAllBookings() async throws -> [BookingData]
    func createBooking(status: String, employeeID: String, boardroomID: String, date: Int) async throws -> BookingData
    func updateBookingPUT(id: String, status: String, employeeID: String, boardroomID: String, date: Int) async throws -> BookingData
    func deleteBooking(id: String) async throws -> Bool
}

struct BookingsService: BookingsServicing {

    private struct AirtableRecordsResponse<T: Decodable>: Decodable {
        let records: [T]
    }

    private struct AirtableErrorResponse: Decodable {
        let error: AirtableError
        struct AirtableError: Decodable {
            let type: String
            let message: String
        }
    }

    private struct CreateBookingRequest: Encodable {
        let records: [Record]
        struct Record: Encodable { let fields: Fields }
        struct Fields: Encodable {
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
    }

    private struct UpdateBookingRequest: Encodable {
        let records: [Record]
        struct Record: Encodable { let id: String; let fields: Fields }
        struct Fields: Encodable {
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
    }

    private struct DeleteResponse: Decodable {
        let records: [DeletedRecord]
        struct DeletedRecord: Decodable {
            let id: String
            let deleted: Bool
        }
    }

    func getAllBookings() async throws -> [BookingData] {
        let url = try baseURL()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setHeaders(&request)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(AirtableRecordsResponse<BookingData>.self, from: data)
        return decoded.records
    }

    func createBooking(status: String = "Confirmed", employeeID: String, boardroomID: String, date: Int) async throws -> BookingData {
        let url = try baseURL()

        let body = CreateBookingRequest(records: [
            .init(fields: .init(status: status, employeeID: employeeID, boardroomID: boardroomID, date: date))
        ])
        let jsonData = try JSONEncoder().encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(AirtableRecordsResponse<BookingData>.self, from: data)
        guard let created = decoded.records.first else { throw BookingsServiceError.invalidData }
        return created
    }

    func updateBookingPUT(id: String, status: String, employeeID: String, boardroomID: String, date: Int) async throws -> BookingData {
        let url = try baseURL()

        let body = UpdateBookingRequest(records: [
            .init(id: id, fields: .init(status: status, employeeID: employeeID, boardroomID: boardroomID, date: date))
        ])
        let jsonData = try JSONEncoder().encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        setHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(AirtableRecordsResponse<BookingData>.self, from: data)
        guard let updated = decoded.records.first else { throw BookingsServiceError.invalidData }
        return updated
    }

    func deleteBooking(id: String) async throws -> Bool {
        var components = try URLComponents(url: baseURL(), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "records[]", value: id)]
        guard let url = components?.url else { throw BookingsServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        setHeaders(&request)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(DeleteResponse.self, from: data)
        return decoded.records.first?.deleted == true
    }

    private func baseURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/\(AirtableConfig.baseID)/\(AirtableConfig.bookingsTable)"
        guard let url = components.url else { throw BookingsServiceError.invalidURL }
        return url
    }

    private func setHeaders(_ request: inout URLRequest) {
        if let token = try? AirtableConfig.apiToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw BookingsServiceError.invalidResponse(statusCode: -1, message: "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            throw BookingsServiceError.invalidResponse(statusCode: http.statusCode, message: parseAirtableError(data))
        }
    }

    private func parseAirtableError(_ data: Data) -> String {
        if let err = try? JSONDecoder().decode(AirtableErrorResponse.self, from: data) {
            return "\(err.error.type): \(err.error.message)"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}


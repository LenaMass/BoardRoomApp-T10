import Foundation

struct logindata: Codable {
    let employeeNumber: Int
    let name: String
    let jobTitle: String
    let password: String
    let email: String
    var recordID: String? = nil

    enum CodingKeys: String, CodingKey {
        case employeeNumber = "EmployeeNumber"
        case name
        case jobTitle = "job_title"
        case password
        case email
    }

    struct AirtableResponse: Codable {
        let records: [Record]
    }

    struct Record: Codable {
        let id: String
        let fields: logindata
    }

    private struct AirtableErrorResponse: Codable {
        let error: AirtableError
        struct AirtableError: Codable {
            let type: String
            let message: String
        }
    }

    static func login(employeeNumberInput: String, passwordInput: String) async throws -> logindata {
        let empRaw = employeeNumberInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let passRaw = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let emp = Int(empRaw) else { throw EmError.invalidEmployeeNumber }

        let user = try await getUser(employeeNumberInt: emp, employeeNumberString: empRaw)

        let storedPass = user.password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard storedPass == passRaw else { throw EmError.wrongPassword }

        return user
    }

    private static func getUser(employeeNumberInt: Int, employeeNumberString: String) async throws -> logindata {
        let apiToken = try loadToken()

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/employees"

        let formula = "OR({EmployeeNumber}=\(employeeNumberInt),{EmployeeNumber}=\"\(employeeNumberString)\")"
        components.queryItems = [
            URLQueryItem(name: "filterByFormula", value: formula),
            URLQueryItem(name: "maxRecords", value: "1")
        ]

        guard let url = components.url else { throw EmError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw EmError.invalidResponse(statusCode: -1, message: "No HTTP response")
        }

        guard http.statusCode == 200 else {
            throw EmError.invalidResponse(statusCode: http.statusCode, message: parseAirtableErrorMessage(from: data))
        }

        let decoded = try JSONDecoder().decode(AirtableResponse.self, from: data)

        guard let record = decoded.records.first else {
            throw EmError.userNotFound
        }

        var user = record.fields
        user.recordID = record.id
        return user
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
            throw EmError.missingAPIToken
        }
        return apiToken
    }
}


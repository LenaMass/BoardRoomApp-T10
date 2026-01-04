import Foundation

struct logindata: Codable {
    let employeeNumber: Int
    let name: String
    let jobTitle: String
    let password: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case employeeNumber = "EmployeeNumber"
        case name
        case jobTitle = "job_title"
        case password
        case email
    }

    enum EmError: Error {
        case invalidURL
        case invalidResponse
        case invalidData
        case missingAPIToken
    }

    struct AirtableResponse: Codable {
        let records: [Record]
    }

    struct Record: Codable {
        let fields: logindata
    }

    static func getUser(logindata employeeNumber: Int) async throws -> logindata {

        guard let apiToken = Bundle.main.infoDictionary?["APIToken"] as? String,
              !apiToken.isEmpty,
              !apiToken.contains("$(") else {
            throw EmError.missingAPIToken
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/appElKqRPusTLsnNe/employees"

        guard let url = components.url else {
            throw EmError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(apiToken)",
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw EmError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(AirtableResponse.self, from: data)

        guard let user = decoded.records
            .map({ $0.fields })
            .first(where: { $0.employeeNumber == employeeNumber }) else {
            throw EmError.invalidData
        }

        return user
    }
    static func login(
        employeeNumber: Int,
        password: String
    ) async throws -> logindata {

        let user = try await getUser(logindata: employeeNumber)

        guard user.password == password else {
            throw EmError.invalidData
        }

        return user
    }
}


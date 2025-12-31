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
        case invaildURL
        case invalidResponse
        case invalidData
    }
    
    struct AirtableResponse: Codable {
        let records: [Record]
    }
    
    struct Record: Codable {
        let fields: logindata
    }
    
    static func getUser(logindata: Int) async throws -> logindata {

        let endpoint = "" //API SPOT

        guard let url = URL(string: endpoint) else {
            throw EmError.invaildURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "", //TOKEN
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200 else {
            throw EmError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(AirtableResponse.self, from: data)

        guard let user = decoded.records
            .map({ $0.fields })
            .first(where: { $0.employeeNumber == logindata }) else {
            throw EmError.invalidData
        }

        return user
    }

    static func login(
        employeeNumber: Int,
        password: String
    ) async throws -> logindata {

        let user = try await getUser(logindata: employeeNumber)

        if user.password != password {
            throw EmError.invalidData
        }

        return user
    }

}



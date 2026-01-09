import Foundation

enum AirtableConfig {
    static let baseID = "appElKqRPusTLsnNe"
    static let bookingsTable = "bookings"

    static func apiToken() throws -> String {
        guard let apiToken = Bundle.main.infoDictionary?["APIToken"] as? String,
              !apiToken.isEmpty,
              !apiToken.contains("$(") else {
            throw BookingsServiceError.missingAPIToken
        }
        return apiToken
    }
}


import Foundation

enum EmError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int, message: String)
    case userNotFound
    case wrongPassword
    case invalidEmployeeNumber
    case missingAPIToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse(let code, let message):
            return "Airtable error (\(code)): \(message)"
        case .userNotFound:
            return "Employee not found"
        case .wrongPassword:
            return "Incorrect password"
        case .invalidEmployeeNumber:
            return "Invalid job number"
        case .missingAPIToken:
            return "Missing APIToken"
        }
    }
}

enum BoardroomsAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case missingAPIToken

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .missingAPIToken: return "Missing APIToken"
        }
    }
}


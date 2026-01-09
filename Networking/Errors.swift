import Foundation

enum EmError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case missingAPIToken

}
//
//enum BookingError: Error, LocalizedError {
//    case invalidResponse(statusCode: Int, message: String)
//    case invalidData
//    case missingAPIToken
//
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL"
//        case .invalidResponse(let code, let message):
//            return "Airtable request failed (\(code)): \(message)"
//        case .invalidData:
//            return "Invalid response data"
//        case .missingAPIToken:
//            return "Missing APIToken in Info.plist"
//        }
//    }
//}

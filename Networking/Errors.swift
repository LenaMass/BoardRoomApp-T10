import Foundation

enum EmError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case missingAPIToken

}

enum BoardroomsAPIError: Error {
    case invalidURL
    case invalidResponse
    case missingAPIToken
}

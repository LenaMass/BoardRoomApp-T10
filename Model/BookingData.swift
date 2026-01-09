import Foundation

struct BookingData: Codable, Identifiable, Hashable {
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
}

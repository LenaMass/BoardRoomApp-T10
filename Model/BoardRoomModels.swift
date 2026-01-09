import Foundation

struct BoardroomsResponse: Decodable {
    let records: [BoardroomRecord]
}

struct BoardroomRecord: Decodable, Identifiable {
    let id: String
    let createdTime: String?
    let fields: BoardroomFields?
}

struct BoardroomFields: Decodable {
    let name: String?
    let floorNo: Int?
    let seatNo: Int?
    let description: String?
    let facilities: [String]?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case floorNo = "floor_no"
        case seatNo = "seat_no"
        case description
        case facilities
        case imageURL = "image_url"
    }
}


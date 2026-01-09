import Foundation

struct DayModel: Identifiable {
    let id = UUID()
    let date: Date
    let day: String
    let weekDay: String
}

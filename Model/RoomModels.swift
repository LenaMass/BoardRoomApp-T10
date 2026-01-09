
import Foundation

enum RoomFeature: Hashable {
    case wifi
    case screen
    case mic
    case control

    var systemImageName: String {
        switch self {
        case .wifi:    return "wifi"
        case .screen:  return "display"
        case .mic:     return "mic.fill"
        case .control: return "slider.horizontal.3"
        }
    }

    var label: String {
        switch self {
        case .wifi:    return "Wi-Fi"
        case .screen:  return "Screen"
        case .mic:     return "Mic"
        case .control: return "Control"
        }
    }
}

struct RoomInfo: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let floor: String
    let people: String
    let imageName: String
    let imageURL: String?
    let features: [RoomFeature]
    let description: String
}

import SwiftUI

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

struct BannerView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.OR_1)

            Circle()
                .fill(Color.blueButton)
                .frame(width: 75, height: 70)
                .offset(x: -169, y: 77)

            Image("Group 8777")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 110)
                .offset(x: 128, y: -27)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("All board rooms")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 15))

                    Text("Available today")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack {
                    Spacer()
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("Book now")
                                .foregroundColor(.white)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 50)
                                .overlay(
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 27, weight: .bold))
                                        .foregroundColor(Color.OR_1)
                                )
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 22)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 138)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct DayChip: View {
    let day: String
    let weekDay: String
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(weekDay)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(day)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.OR_1 : .clear)
                        .overlay(
                            Circle()
                                .stroke(.gray.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                )
        }
    }
}

struct EmptyMyBookingCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6)

            VStack(spacing: 8) {
                Text("No bookings made yet")
                    .font(.headline)

                Text("Book a room and it will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 18)
        }
    }
}

struct RoomCard: View {

    enum Status {
        case available
        case unavailable

        var title: String {
            switch self {
            case .available: return "Available"
            case .unavailable: return "Unavailable"
            }
        }

        var bg: Color {
            switch self {
            case .available: return .green.opacity(0.18)
            case .unavailable: return .red.opacity(0.18)
            }
        }

        var fg: Color {
            switch self {
            case .available: return .green
            case .unavailable: return .red
            }
        }
    }

    enum Tag {
        case date(String)
        case status(Status)
    }

    var title: String
    var floor: String
    var people: String
    var tag: Tag?
    var imageName: String
    var imageURL: String?
    var features: [RoomFeature] = []

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                RoomCardImage(imageName: imageName, imageURL: imageURL)
                    .frame(width: 106, height: 106)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)

                    Text(floor)
                        .foregroundColor(.gray)
                        .font(.subheadline)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text(people)
                    }
                    .foregroundColor(.red)
                    .font(.caption2)

                    HStack(spacing: 10) {
                        ForEach(features, id: \.self) { feature in
                            Image(systemName: feature.systemImageName)
                        }
                    }
                    .foregroundColor(.gray)
                    .font(.caption2)
                }

                Spacer()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 6)

            if let tag = tag {
                switch tag {
                case .date(let txt):
                    Text(txt)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blueButton)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)

                case .status(let s):
                    Text(s.title)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(s.bg)
                        .foregroundColor(s.fg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                }
            }
        }
    }
}

struct RoomCardImage: View {
    let imageName: String
    let imageURL: String?

    var body: some View {
        if let imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(imageName).resizable().scaledToFill()
                }
            }
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
        }
    }
}


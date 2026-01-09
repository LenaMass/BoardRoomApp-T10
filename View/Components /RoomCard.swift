import   SwiftUI

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


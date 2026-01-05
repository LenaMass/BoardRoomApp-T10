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

struct BoardRoomsView: View {

    struct DayModel: Identifiable {
        let id = UUID()
        let date: Date
        let day: String
        let weekDay: String
    }

    @State private var boardrooms: [BoardroomRecord] = []
    @State private var selectedDayIndex: Int = 0
    @State private var bookings: [BookingData] = []
    @State private var bookingsError: String = ""
    @State private var isLoadingBookings = false

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var todayTagText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: Date())
    }

    private var days: [DayModel] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let range = calendar.range(of: .day, in: .month, for: today) ?? 1..<2

        let formatterDay = DateFormatter()
        formatterDay.dateFormat = "d"

        let formatterWeekday = DateFormatter()
        formatterWeekday.dateFormat = "EEE"

        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return DayModel(
                date: date,
                day: formatterDay.string(from: date),
                weekDay: formatterWeekday.string(from: date)
            )
        }
    }

    private var todayIndexInMonth: Int {
        let calendar = Calendar.current
        let today = Date()
        let day = calendar.component(.day, from: today)
        let idx = day - 1
        return max(0, min(idx, days.count - 1))
    }

    private var selectedDate: Date {
        guard days.indices.contains(selectedDayIndex) else { return Date() }
        return days[selectedDayIndex].date
    }

    private let myRoom = RoomInfo(
        title: "Creative Space",
        floor: "Floor 5",
        people: "1",
        imageName: "room1",
        imageURL: nil,
        features: [.wifi],
        description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
    )

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    BannerView()
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        HStack {
                            Text("My booking")
                                .font(.headline)
                            Spacer()
                            Text("See All")
                                .foregroundColor(Color.OR_1)
                        }

                        NavigationLink {
                            RoomDetailView(room: myRoom, initialDate: Date()) {
                                await fetchData()
                            }
                        } label: {
                            RoomCard(
                                title: myRoom.title,
                                floor: myRoom.floor,
                                people: myRoom.people,
                                tag: .date(todayTagText),
                                imageName: myRoom.imageName,
                                imageURL: myRoom.imageURL,
                                features: myRoom.features
                            )
                            .frame(height: 122)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 16) {

                        HStack {
                            Text("All bookings for \(monthTitle)")
                                .font(.headline)

                            Spacer()

                            if isLoadingBookings {
                                ProgressView()
                            } else {
                                Text("Bookings: \(bookings.count)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        if !bookingsError.isEmpty {
                            Text(bookingsError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(days.indices, id: \.self) { index in
                                    let d = days[index]

                                    Button {
                                        selectedDayIndex = index
                                    } label: {
                                        DayChip(
                                            day: d.day,
                                            weekDay: d.weekDay,
                                            isSelected: selectedDayIndex == index
                                        )
                                    }
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(apiRooms.indices, id: \.self) { i in
                                let r = apiRooms[i]

                                let isUnavailable = BoardroomsAPI.isRoomBooked(
                                    roomTitle: r.title,
                                    bookings: bookings,
                                    boardrooms: boardrooms,
                                    on: selectedDate
                                )
                                let status: RoomCard.Status = isUnavailable ? .unavailable : .available

                                NavigationLink {
                                    RoomDetailView(room: r, initialDate: selectedDate) {
                                        await fetchData()
                                    }
                                } label: {
                                    RoomCard(
                                        title: r.title,
                                        floor: r.floor,
                                        people: r.people,
                                        tag: .status(status),
                                        imageName: r.imageName,
                                        imageURL: r.imageURL,
                                        features: r.features
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Board Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blueButton, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                selectedDayIndex = todayIndexInMonth
                await fetchData()
            }
            .refreshable {
                await fetchData()
            }
        }
    }

    private var apiRooms: [RoomInfo] {
        boardrooms.compactMap { rec in
            guard let f = rec.fields else { return nil }
            let title = f.name ?? ""
            if title.isEmpty { return nil }

            let floor = "Floor \(f.floorNo ?? 0)"
            let people = "\(f.seatNo ?? 0)"
            let desc = f.description ?? ""
            let imgURL = f.imageURL
            let features = mapFacilitiesToFeatures(f.facilities ?? [])

            return RoomInfo(
                title: title,
                floor: floor,
                people: people,
                imageName: "room1",
                imageURL: imgURL,
                features: features,
                description: desc
            )
        }
    }

    private func mapFacilitiesToFeatures(_ facilities: [String]) -> [RoomFeature] {
        let lower = facilities.map { $0.lowercased() }
        var out: [RoomFeature] = []

        if lower.contains(where: { $0.contains("wifi") }) { out.append(.wifi) }
        if lower.contains(where: { $0.contains("screen") || $0.contains("display") || $0.contains("tv") }) { out.append(.screen) }
        if lower.contains(where: { $0.contains("mic") }) { out.append(.mic) }
        if lower.contains(where: { $0.contains("control") || $0.contains("controller") }) { out.append(.control) }

        return out
    }

    @MainActor
    private func fetchData() async {
        isLoadingBookings = true
        bookingsError = ""
        do {
            let result = try await BoardroomsAPI.fetchData()
            bookings = result.bookings
            boardrooms = result.boardrooms
        } catch {
            bookingsError = "Failed to load data"
        }
        isLoadingBookings = false
    }
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
        .frame(width: 358, height: 138)
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

struct RoomCard: View {

    enum Status {
        case available
        case unavailable

        var title: String {
            switch self {
            case .available:   return "Available"
            case .unavailable: return "Unavailable"
            }
        }

        var bg: Color {
            switch self {
            case .available:   return .green.opacity(0.18)
            case .unavailable: return .red.opacity(0.18)
            }
        }

        var fg: Color {
            switch self {
            case .available:   return .green
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

#Preview {
    BoardRoomsView()
}


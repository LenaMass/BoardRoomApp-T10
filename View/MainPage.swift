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

    @AppStorage("myBookingIDs") private var myBookingIDsJSON: String = "[]"

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
            return DayModel(date: date, day: formatterDay.string(from: date), weekDay: formatterWeekday.string(from: date))
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

    private var myBookingIDs: Set<String> {
        (try? Set(JSONDecoder().decode([String].self, from: Data(myBookingIDsJSON.utf8)))) ?? []
    }

    private var myBookings: [BookingData] {
        bookings.filter { myBookingIDs.contains($0.id) }
    }

    private var nextMyBooking: BookingData? {
        let todayInt = BoardroomsAPI.dateInt(from: Date())
        return myBookings
            .filter { $0.fields.date >= todayInt }
            .sorted { $0.fields.date < $1.fields.date }
            .first
    }

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

                            NavigationLink {
                                BookingView(
                                    bookings: myBookings,
                                    boardrooms: boardrooms
                                )
                            } label: {
                                Text("See All")
                                    .foregroundColor(Color.OR_1)
                            }
                            .buttonStyle(.plain)
                        }

                        if let b = nextMyBooking,
                           let bookedDate = dateFromInt(b.fields.date),
                           let room = roomInfo(for: b) {

                            NavigationLink {
                                RoomDetailView(room: room, initialDate: bookedDate) {
                                    await fetchData()
                                }
                            } label: {
                                RoomCard(
                                    title: room.title,
                                    floor: room.floor,
                                    people: room.people,
                                    tag: .date(shortDateText(from: bookedDate)),
                                    imageName: room.imageName,
                                    imageURL: room.imageURL,
                                    features: room.features
                                )
                                .frame(height: 122)
                            }
                            .buttonStyle(.plain)

                        } else {
                            EmptyMyBookingCard()
                                .frame(height: 122)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {

                        HStack {
                            Text("All bookings for \(monthTitle)")
                                .font(.headline)

                            Spacer()

                            if isLoadingBookings {
                                ProgressView()
                            } else {
                                let cal = Calendar.current
                                let y = cal.component(.year, from: Date())
                                let m = cal.component(.month, from: Date())
                                let thisMonthCount = bookings.filter {
                                    $0.fields.date / 10000 == y &&
                                    ($0.fields.date / 100) % 100 == m
                                }.count

                                Text("Bookings this month: \(thisMonthCount)")
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
                                    Button { selectedDayIndex = index } label: {
                                        DayChip(day: d.day, weekDay: d.weekDay, isSelected: selectedDayIndex == index)
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

    private func roomInfo(for booking: BookingData) -> RoomInfo? {
        guard let rec = boardrooms.first(where: { $0.id == booking.fields.boardroomID }),
              let f = rec.fields,
              let title = f.name,
              !title.isEmpty else { return nil }

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

    private func dateFromInt(_ di: Int) -> Date? {
        let y = di / 10000
        let m = (di / 100) % 100
        let d = di % 100
        return Calendar.current.date(from: DateComponents(year: y, month: m, day: d))
    }

    private func shortDateText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
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

struct EmptyMyBookingCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6)

            VStack(spacing: 6) {
                Text("No bookings made yet")
                    .font(.headline)
                    .foregroundColor(.black)

                Text("Book a room and it will appear here.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
        }
    }
}


import SwiftUI

struct BoardRoomsView: View {

    struct DayModel: Identifiable {
        let id = UUID()
        let date: Date
        let day: String
        let weekDay: String
    }

    let calendar = BoardroomsAPI.gregorianCalendar

    @AppStorage("employeeID") private var employeeID: String = ""

    @State private var boardrooms: [BoardroomRecord] = []
    @State private var selectedDayIndex: Int = 0
    @State private var bookings: [BookingData] = []
    @State private var bookingsError: String = ""
    @State private var isLoadingBookings = false

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var days: [DayModel] {
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let range = calendar.range(of: .day, in: .month, for: today) ?? 1..<2

        let formatterDay = DateFormatter()
        formatterDay.calendar = calendar
        formatterDay.dateFormat = "d"

        let formatterWeekday = DateFormatter()
        formatterWeekday.calendar = calendar
        formatterWeekday.dateFormat = "EEE"

        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return DayModel(date: date, day: formatterDay.string(from: date), weekDay: formatterWeekday.string(from: date))
        }
    }

    private var todayIndexInMonth: Int {
        let day = calendar.component(.day, from: Date())
        return max(0, min(day - 1, days.count - 1))
    }

    private var selectedDate: Date {
        guard days.indices.contains(selectedDayIndex) else { return Date() }
        return days[selectedDayIndex].date
    }

    private var apiRooms: [RoomInfo] {
        boardrooms.compactMap { rec in
            guard let f = rec.fields, let title = f.name, !title.isEmpty else { return nil }
            return RoomInfo(
                title: title,
                floor: "Floor \(f.floorNo ?? 0)",
                people: "\(f.seatNo ?? 0)",
                imageName: "room1",
                imageURL: f.imageURL,
                features: mapFacilitiesToFeatures(f.facilities ?? []),
                description: f.description ?? ""
            )
        }
    }

    private var validBookings: [BookingData] {
        bookings.filter {
            ($0.fields.boardroomID ?? "").isEmpty == false &&
            $0.fields.date != nil
        }
    }

    private var myBookings: [BookingData] {
        validBookings.filter { ($0.fields.employeeID ?? "") == employeeID }
    }

    private var nextMyBooking: BookingData? {
        let todayInt = BoardroomsAPI.dateInt(from: Date())
        return myBookings
            .filter { ($0.fields.date ?? 0) >= todayInt }
            .sorted { ($0.fields.date ?? 0) < ($1.fields.date ?? 0) }
            .first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.screenBG
                    .ignoresSafeArea()

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
                                        boardrooms: boardrooms,
                                        onChanged: {
                                            await fetchData()
                                        }
                                    )
                                } label: {
                                    Text("See All")
                                        .foregroundColor(Color.OR_1)
                                }
                                .buttonStyle(.plain)
                            }

                            if let b = nextMyBooking,
                               let dateInt = b.fields.date,
                               let bookedDate = BoardroomsAPI.dateFromInt(dateInt),
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
                                        tag: .date(BoardroomsAPI.shortDateText(from: dateInt)),
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
                                    let y = calendar.component(.year, from: Date())
                                    let m = calendar.component(.month, from: Date())
                                    let count = validBookings.filter {
                                        let date = $0.fields.date ?? 0
                                        return date / 10000 == y && (date / 100) % 100 == m
                                    }.count

                                    Text("Bookings this month: \(count)")
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

                                    let unavailable = BoardroomsAPI.isRoomBooked(
                                        roomTitle: r.title,
                                        bookings: validBookings,
                                        boardrooms: boardrooms,
                                        on: selectedDate
                                    )

                                    NavigationLink {
                                        RoomDetailView(room: r, initialDate: selectedDate) {
                                            await fetchData()
                                        }
                                    } label: {
                                        RoomCard(
                                            title: r.title,
                                            floor: r.floor,
                                            people: r.people,
                                            tag: .status(unavailable ? .unavailable : .available),
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
        guard let roomID = booking.fields.boardroomID,
              let rec = boardrooms.first(where: { $0.id == roomID }),
              let f = rec.fields,
              let title = f.name else { return nil }

        return RoomInfo(
            title: title,
            floor: "Floor \(f.floorNo ?? 0)",
            people: "\(f.seatNo ?? 0)",
            imageName: "room1",
            imageURL: f.imageURL,
            features: mapFacilitiesToFeatures(f.facilities ?? []),
            description: f.description ?? ""
        )
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
            bookingsError = error.localizedDescription
        }
        isLoadingBookings = false
    }
}


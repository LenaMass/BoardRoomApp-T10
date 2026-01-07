import SwiftUI

struct RoomDetailView: View {
    let room: RoomInfo
    let initialDate: Date
    let onChanged: (() async -> Void)?

    
    struct DayModel: Identifiable {
        let id = UUID()
        let date: Date
        let day: String
        let weekDay: String
    }

    @AppStorage("employeeID") private var employeeID: String = ""

    @State private var selectedDayIndex: Int = 0
    @State private var boardrooms: [BoardroomRecord] = []
    @State private var bookings: [BookingData] = []
    @State private var errorText: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var successDate: Date = Date()

    private var calendar: Calendar { BoardroomsAPI.gregorianCalendar }

    private var monthTitle: String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "MMMM"
        return f.string(from: initialDate)
    }

    private var days: [DayModel] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: initialDate)) ?? initialDate
        let range = calendar.range(of: .day, in: .month, for: initialDate) ?? 1..<2

        let fd = DateFormatter()
        fd.calendar = calendar
        fd.locale = Locale(identifier: "en_US_POSIX")
        fd.timeZone = .current
        fd.dateFormat = "d"

        let fw = DateFormatter()
        fw.calendar = calendar
        fw.locale = Locale(identifier: "en_US_POSIX")
        fw.timeZone = .current
        fw.dateFormat = "EEE"

        return range.compactMap { day in
            guard let d = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return DayModel(date: d, day: fd.string(from: d), weekDay: fw.string(from: d))
        }
    }

    private var selectedDate: Date {
        guard days.indices.contains(selectedDayIndex) else { return initialDate }
        return days[selectedDayIndex].date
    }

    private var roomRecordID: String? {
        BoardroomsAPI.boardroomRecordID(for: room.title, in: boardrooms)
    }

    private var isUnavailableSelectedDay: Bool {
        BoardroomsAPI.isRoomBooked(
            roomTitle: room.title,
            bookings: bookings,
            boardrooms: boardrooms,
            on: selectedDate
        )
    }

    var body: some View {
        ZStack {
            Color.screenBG
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    Group {
                        if let urlStr = room.imageURL,
                           let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        Color.white
                                        ProgressView()
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Image(room.imageName)
                                        .resizable()
                                        .scaledToFill()
                                @unknown default:
                                    Image(room.imageName)
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                        } else {
                            Image(room.imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(height: 260)
                    .clipped()

                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location")
                            Text(room.floor)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                            Text(room.people)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(room.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Facilities")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(room.features, id: \.self) { feature in
                                HStack(spacing: 6) {
                                    Image(systemName: feature.systemImageName)
                                    Text(feature.label)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("All bookings for \(monthTitle)")
                            .font(.headline)

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
                                        .opacity(isLoading ? 0.6 : 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    if !errorText.isEmpty {
                        Text(errorText)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    Button {
                        Task { await bookSelectedDay() }
                    } label: {
                        Text(isUnavailableSelectedDay ? "Unavailable" : "Booking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isUnavailableSelectedDay ? Color.gray : Color.OR_1)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .disabled(isUnavailableSelectedDay || isLoading)

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationTitle(room.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.blueButton, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            let day = calendar.component(.day, from: initialDate)
            selectedDayIndex = max(0, min(day - 1, days.count - 1))
            await fetchData()
        }
        .fullScreenCover(isPresented: $showSuccess, onDismiss: {
            Task { if let onChanged { await onChanged() } }
        }) {
            BookingSuccessView(roomName: room.title, date: successDate)
        }
    }

    @MainActor
    private func fetchData() async {
        isLoading = true
        errorText = ""
        do {
            let result = try await BoardroomsAPI.fetchData()
            bookings = result.bookings
            boardrooms = result.boardrooms
        } catch {
            errorText = "Failed to load data"
        }
        isLoading = false
    }

    private func bookSelectedDay() async {
        errorText = ""
        guard !employeeID.isEmpty else {
            errorText = "Employee not logged in"
            return
        }
        guard let boardroomID = roomRecordID else {
            errorText = "Missing boardroom id"
            return
        }

        let di = BoardroomsAPI.dateInt(from: selectedDate)

        do {
            _ = try await BookingData.createBooking(
                status: "Confirmed",
                employeeID: employeeID,
                boardroomID: boardroomID,
                date: di
            )
            successDate = selectedDate
            showSuccess = true
            await fetchData()
        } catch {
            errorText = error.localizedDescription
        }
    }
}


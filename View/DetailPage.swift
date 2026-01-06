import SwiftUI

struct RoomDetailView: View {
    let room: RoomInfo
    let initialDate: Date
    let onBooked: () async -> Void

    let calendar = BoardroomsAPI.gregorianCalendar

    struct DayModel: Identifiable {
        let id = UUID()
        let date: Date
        let day: String
        let weekDay: String
    }

    @AppStorage("employeeRecordID") private var employeeID: String = ""
    @AppStorage("myBookingIDs") private var myBookingIDsJSON: String = "[]"

    @State private var selectedDayIndex = 0
    @State private var isBooking = false
    @State private var bookingMessage = ""
    @State private var bookingError = ""

    init(room: RoomInfo, initialDate: Date = Date(), onBooked: @escaping () async -> Void = {}) {
        self.room = room
        self.initialDate = initialDate
        self.onBooked = onBooked
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM"
        return formatter.string(from: initialDate)
    }

    private var days: [DayModel] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: initialDate)) ?? initialDate
        let range = calendar.range(of: .day, in: .month, for: initialDate) ?? 1..<2

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

    private var initialIndexInMonth: Int {
        let day = calendar.component(.day, from: initialDate)
        let idx = day - 1
        return max(0, min(idx, days.count - 1))
    }

    private var selectedDate: Date {
        guard days.indices.contains(selectedDayIndex) else { return initialDate }
        return days[selectedDayIndex].date
    }

    private var selectedDateInt: Int {
        BoardroomsAPI.dateInt(from: selectedDate)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                if let urlString = room.imageURL,
                   let url = URL(string: urlString),
                   !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Image(room.imageName).resizable().scaledToFill()
                        }
                    }
                    .frame(height: 260)
                    .clipped()
                } else {
                    Image(room.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 260)
                        .clipped()
                }

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
                        .background(Color(.systemGray6))
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
                            .background(Color(.systemGray6))
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
                                Button { selectedDayIndex = index } label: {
                                    DayChip(day: d.day, weekDay: d.weekDay, isSelected: selectedDayIndex == index)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                if !bookingError.isEmpty {
                    Text(bookingError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                }

                if !bookingMessage.isEmpty {
                    Text(bookingMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                }

                Button {
                    Task { await bookRoomForSelectedDay() }
                } label: {
                    Text(isBooking ? "Booking..." : "Booking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.OR_1)
                        .cornerRadius(12)
                }
                .disabled(isBooking)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 60)
            }
        }
        .navigationTitle(room.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.blueButton, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            selectedDayIndex = initialIndexInMonth
        }
    }

    @MainActor
    private func bookRoomForSelectedDay() async {
        bookingError = ""
        bookingMessage = ""

        guard !employeeID.isEmpty else {
            bookingError = "Employee not logged in"
            return
        }

        isBooking = true
        defer { isBooking = false }

        do {
            let data = try await BoardroomsAPI.fetchData()

            guard let roomID = BoardroomsAPI.boardroomRecordID(for: room.title, in: data.boardrooms) else {
                bookingError = "Room id not found in Airtable"
                return
            }

            let alreadyBooked = data.bookings.contains {
                ($0.fields.boardroomID ?? "") == roomID && ($0.fields.date ?? 0) == selectedDateInt
            }

            if alreadyBooked {
                bookingError = "This room is already booked for the selected day"
                return
            }

            let created = try await BookingData.createBooking(
                status: "Confirmed",
                employeeID: employeeID,
                boardroomID: roomID,
                date: selectedDateInt
            )

            saveMyBookingID(created.id)

            bookingMessage = "Booked successfully"
            await onBooked()
        } catch {
            bookingError = error.localizedDescription
        }
    }

    private func saveMyBookingID(_ id: String) {
        var ids = (try? JSONDecoder().decode([String].self, from: Data(myBookingIDsJSON.utf8))) ?? []
        if ids.contains(id) { return }
        ids.append(id)
        if let data = try? JSONEncoder().encode(ids),
           let str = String(data: data, encoding: .utf8) {
            myBookingIDsJSON = str
        }
    }
}


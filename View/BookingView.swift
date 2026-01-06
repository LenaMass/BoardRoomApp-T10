import SwiftUI

struct BookingView: View {

    let bookings: [BookingData]
    let boardrooms: [BoardroomRecord]
    let onChanged: (() async -> Void)?

    @State private var busyIDs: Set<String> = []
    @State private var errorText: String = ""

    @State private var editingBooking: BookingData? = nil
    @State private var editingSelectedIndex: Int = 0

    private var calendar: Calendar { BoardroomsAPI.gregorianCalendar }

    private var displayBookings: [(booking: BookingData, dateInt: Int, dateText: String, roomID: String)] {
        bookings.compactMap { booking in
            guard let d = booking.fields.date else { return nil }
            guard let r = booking.fields.boardroomID, !r.isEmpty else { return nil }
            return (booking, d, BoardroomsAPI.shortDateText(from: d), r)
        }
        .sorted { $0.dateInt < $1.dateInt }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {

                if !errorText.isEmpty {
                    Text(errorText)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                if displayBookings.isEmpty {
                    EmptyMyBookingCard()
                        .frame(height: 140)
                        .padding(.top, 16)
                } else {
                    ForEach(displayBookings, id: \.booking.id) { item in
                        let booking = item.booking
                        let dateText = item.dateText
                        let roomID = item.roomID

                        let roomName = BoardroomsAPI.boardroomName(for: roomID, in: boardrooms) ?? "Boardroom"
                        let room = boardrooms.first(where: { $0.id == roomID })?.fields

                        let floorText = {
                            if let f = room?.floorNo { return "Floor \(f)" }
                            return ""
                        }()

                        let peopleText = {
                            if let s = room?.seatNo { return "\(s)" }
                            return ""
                        }()

                        VStack(spacing: 10) {
                            RoomCard(
                                title: roomName,
                                floor: floorText,
                                people: peopleText,
                                tag: .date(dateText),
                                imageName: "room1",
                                imageURL: room?.imageURL,
                                features: mapFacilitiesToFeatures(room?.facilities ?? [])
                            )

                            HStack(spacing: 12) {
                                Button {
                                    startEditing(booking: booking)
                                } label: {
                                    Text("Edit date")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.blueButton)
                                        .cornerRadius(10)
                                }
                                .disabled(busyIDs.contains(booking.id))

                                Button {
                                    Task { await deleteBooking(booking: booking) }
                                } label: {
                                    Text("Delete")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                                .disabled(busyIDs.contains(booking.id))

                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingBooking) { booking in
            EditBookingDaySheet(
                booking: booking,
                boardrooms: boardrooms,
                initialIndex: editingSelectedIndex,
                onSave: { chosenDate in
                    await saveEditedDate(for: booking, newDate: chosenDate)
                },
                onCancel: {
                    editingBooking = nil
                }
            )
        }
    }

    private func startEditing(booking: BookingData) {
        errorText = ""
        let currentDate = (booking.fields.date.flatMap { BoardroomsAPI.dateFromInt($0) }) ?? Date()
        editingSelectedIndex = monthIndex(for: currentDate)
        editingBooking = booking
    }

    private func saveEditedDate(for booking: BookingData, newDate: Date) async {
        errorText = ""
        busyIDs.insert(booking.id)
        defer { busyIDs.remove(booking.id) }

        let newDateInt = BoardroomsAPI.dateInt(from: newDate)

        do {
            _ = try await BookingData.updateBookingDate(
                bookingID: booking.id,
                newDate: newDateInt
            )
            editingBooking = nil
            if let onChanged { await onChanged() }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func deleteBooking(booking: BookingData) async {
        errorText = ""
        busyIDs.insert(booking.id)
        defer { busyIDs.remove(booking.id) }

        do {
            try await BookingData.deleteBooking(bookingID: booking.id)
            if let onChanged { await onChanged() }
        } catch {
            errorText = error.localizedDescription
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

    private func monthIndex(for date: Date) -> Int {
        let day = calendar.component(.day, from: date)
        return max(0, day - 1)
    }
}

private struct EditBookingDaySheet: View {

    let booking: BookingData
    let boardrooms: [BoardroomRecord]
    let initialIndex: Int
    let onSave: (Date) async -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var calendar: Calendar { BoardroomsAPI.gregorianCalendar }

    struct DayModel: Identifiable {
        let id = UUID()
        let date: Date
        let day: String
        let weekDay: String
    }

    @State private var selectedIndex: Int
    @State private var isSaving = false

    init(
        booking: BookingData,
        boardrooms: [BoardroomRecord],
        initialIndex: Int,
        onSave: @escaping (Date) async -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.booking = booking
        self.boardrooms = boardrooms
        self.initialIndex = initialIndex
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedIndex = State(initialValue: initialIndex)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.calendar = calendar
        f.dateFormat = "MMMM"
        return f.string(from: Date())
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

    private var selectedDate: Date {
        guard days.indices.contains(selectedIndex) else { return Date() }
        return days[selectedIndex].date
    }

    private var isPastSelectedDay: Bool {
        let todayStart = calendar.startOfDay(for: Date())
        let pickStart = calendar.startOfDay(for: selectedDate)
        return pickStart < todayStart
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {

                Text("Select a new day")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(days.indices, id: \.self) { i in
                            let d = days[i]
                            Button {
                                selectedIndex = i
                            } label: {
                                DayChip(day: d.day, weekDay: d.weekDay, isSelected: selectedIndex == i)
                                    .opacity(isDayDisabled(days[i].date) ? 0.35 : 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(isDayDisabled(days[i].date))
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
            .navigationTitle("Edit date · \(monthTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            isSaving = true
                            await onSave(selectedDate)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(isSaving || isPastSelectedDay)
                }
            }
        }
    }

    private func isDayDisabled(_ date: Date) -> Bool {
        let todayStart = calendar.startOfDay(for: Date())
        let pickStart = calendar.startOfDay(for: date)
        return pickStart < todayStart
    }
}


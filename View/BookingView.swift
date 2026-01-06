import SwiftUI

struct BookingView: View {

    struct DayModel: Identifiable {
        let id = UUID()
        let date: Date
        let day: String
        let weekDay: String
    }

    let bookings: [BookingData]
    let boardrooms: [BoardroomRecord]
    let onChanged: (() async -> Void)?

    @State private var busyIDs: Set<String> = []
    @State private var errorText: String = ""

    @State private var editingBooking: BookingData?
    @State private var editDayIndex: Int = 0

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "MMMM"
        return f.string(from: Date())
    }

    private var days: [DayModel] {
        let cal = BoardroomsAPI.gregorianCalendar
        let today = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
        let range = cal.range(of: .day, in: .month, for: today) ?? 1..<2

        let fd = DateFormatter()
        fd.locale = Locale(identifier: "en_US_POSIX")
        fd.timeZone = .current
        fd.dateFormat = "d"

        let fw = DateFormatter()
        fw.locale = Locale(identifier: "en_US_POSIX")
        fw.timeZone = .current
        fw.dateFormat = "EEE"

        return range.compactMap { day in
            guard let date = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            return DayModel(date: date, day: fd.string(from: date), weekDay: fw.string(from: date))
        }
    }

    private var displayBookings: [(booking: BookingData, dateInt: Int, dateText: String, roomID: String)] {
        bookings.compactMap { booking in
            guard let dateInt = booking.fields.date else { return nil }
            guard let roomID = booking.fields.boardroomID, !roomID.isEmpty else { return nil }
            return (booking, dateInt, BoardroomsAPI.shortDateText(from: dateInt), roomID)
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
                                    startEdit(booking: booking)
                                } label: {
                                    Text("Edit date (PUT)")
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
                                    Text("Delete (DEL)")
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
        .sheet(item: $editingBooking) { b in
            editSheet(for: b)
                .presentationDetents([.medium])
        }
    }

    private func startEdit(booking: BookingData) {
        errorText = ""
        if let di = booking.fields.date,
           let d = BoardroomsAPI.dateFromInt(di) {
            let cal = BoardroomsAPI.gregorianCalendar
            let day = cal.component(.day, from: d)
            editDayIndex = max(0, min(day - 1, days.count - 1))
        } else {
            editDayIndex = 0
        }
        editingBooking = booking
    }

    private func editSheet(for booking: BookingData) -> some View {
        VStack(spacing: 14) {
            Text("Choose a day in \(monthTitle)")
                .font(.headline)
                .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(days.indices, id: \.self) { index in
                        let d = days[index]
                        Button {
                            editDayIndex = index
                        } label: {
                            DayChip(day: d.day, weekDay: d.weekDay, isSelected: editDayIndex == index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            Button {
                Task { await saveEditedDate(booking: booking) }
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.OR_1)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .disabled(busyIDs.contains(booking.id))

            Spacer(minLength: 6)
        }
    }

    private func saveEditedDate(booking: BookingData) async {
        errorText = ""
        busyIDs.insert(booking.id)
        defer { busyIDs.remove(booking.id) }

        guard let roomID = booking.fields.boardroomID, !roomID.isEmpty else {
            errorText = "Missing boardroom id"
            return
        }
        guard let employeeID = booking.fields.employeeID, !employeeID.isEmpty else {
            errorText = "Missing employee id"
            return
        }
        guard days.indices.contains(editDayIndex) else {
            errorText = "Invalid day"
            return
        }

        let selected = days[editDayIndex].date
        let newDateInt = BoardroomsAPI.dateInt(from: selected)
        let status = booking.fields.status ?? "Confirmed"

        do {
            _ = try await BookingData.updateBookingPUT(
                id: booking.id,
                status: status,
                employeeID: employeeID,
                boardroomID: roomID,
                date: newDateInt
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
            let ok = try await BookingData.deleteBooking(id: booking.id)
            if ok == false { errorText = "Delete failed" }
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
}


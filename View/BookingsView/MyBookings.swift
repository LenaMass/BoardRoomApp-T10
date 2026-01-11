import SwiftUI

@MainActor
struct BookingView: View {
    let bookings: [BookingData]
    let boardrooms: [BoardroomRecord]
    let onChanged: (() async -> Void)?

    @StateObject private var vm: MyBookingsViewModel

    init(
        bookings: [BookingData],
        boardrooms: [BoardroomRecord],
        onChanged: (() async -> Void)? = nil,
        service: BookingsServicing? = nil
    ) {
        self.bookings = bookings
        self.boardrooms = boardrooms
        self.onChanged = onChanged

        let svc = service ?? BookingsService()

        _vm = StateObject(
            wrappedValue: MyBookingsViewModel(
                bookings: bookings,
                boardrooms: boardrooms,
                onChanged: onChanged,
                service: svc
            )
        )
    }

    var body: some View {
        ZStack {
            Color.screenBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if !vm.errorText.isEmpty {
                        Text(vm.errorText)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }

                    if vm.displayBookings.isEmpty {
                        EmptyMyBookingCard()
                            .frame(height: 140)
                            .padding(.top, 16)
                    } else {
                        ForEach(vm.displayBookings) { item in
                            BookingRowView(
                                item: item,
                                boardrooms: boardrooms,
                                isBusy: vm.busyIDs.contains(item.booking.id),
                                onEdit: {
                                    vm.startEdit(booking: item.booking)
                                },
                                onDelete: {
                                    Task { await vm.deleteBooking(item.booking) }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.blueButton, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $vm.editingBooking) { b in
            EditBookingSheetView(
                booking: b,
                monthTitle: vm.monthTitle,
                days: vm.days,
                editDayIndex: $vm.editDayIndex,
                isBusy: vm.busyIDs.contains(b.id),
                onSave: {
                    Task { await vm.saveEditedDate(for: b) }
                }
            )
            .presentationDetents([.medium])
        }
        .task {
            vm.setData(bookings: bookings, boardrooms: boardrooms)
        }
        .onChange(of: bookings) {
            vm.setData(bookings: bookings, boardrooms: boardrooms)
        }
    }
}

private struct BookingRowView: View {
    let item: MyBookingsViewModel.DisplayBooking
    let boardrooms: [BoardroomRecord]
    let isBusy: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var roomFields: BoardroomFields? {
        boardrooms.first(where: { $0.id == item.roomID })?.fields
    }

    private var roomName: String {
        BoardroomsAPI.boardroomName(for: item.roomID, in: boardrooms) ?? "Boardroom"
    }

    private var floorText: String {
        if let f = roomFields?.floorNo { return "Floor \(f)" }
        return ""
    }

    private var peopleText: String {
        if let s = roomFields?.seatNo { return "\(s)" }
        return ""
    }

    private var features: [RoomFeature] {
        mapFacilitiesToFeatures(roomFields?.facilities ?? [])
    }

    var body: some View {
        VStack(spacing: 10) {
            RoomCard(
                title: roomName,
                floor: floorText,
                people: peopleText,
                tag: .date(item.dateText),
                imageName: "room1",
                imageURL: roomFields?.imageURL,
                features: features
            )

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Text("Edit date")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.OR_1)
                        .cornerRadius(10)
                }
                .disabled(isBusy)

                Button(action: onDelete) {
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.crimson)
                        .cornerRadius(10)
                }
                .disabled(isBusy)

                Spacer()
            }
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

private struct EditBookingSheetView: View {
    let booking: BookingData
    let monthTitle: String
    let days: [DayModel]
    @Binding var editDayIndex: Int
    let isBusy: Bool
    let onSave: () -> Void

    var body: some View {
        ZStack {
            Color.screenBG.ignoresSafeArea()

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
                                CalendarDayChip(day: d.day, weekDay: d.weekDay, isSelected: editDayIndex == index)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Button(action: onSave) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.OR_1)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .disabled(isBusy)

                Spacer(minLength: 6)
            }
        }
    }
}


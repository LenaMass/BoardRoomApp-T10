import SwiftUI

struct BookingView: View {

    let bookings: [BookingData]
    let boardrooms: [BoardroomRecord]

    private var displayBookings: [(booking: BookingData, room: RoomInfo, dateText: String)] {
        bookings.compactMap { booking in
            guard
                let dateInt = booking.fields.date,
                let boardroomID = booking.fields.boardroomID,
                let rec = boardrooms.first(where: { $0.id == boardroomID }),
                let f = rec.fields,
                let title = f.name
            else { return nil }

            let room = RoomInfo(
                title: title,
                floor: "Floor \(f.floorNo ?? 0)",
                people: "\(f.seatNo ?? 0)",
                imageName: "room1",
                imageURL: f.imageURL,
                features: mapFacilitiesToFeatures(f.facilities ?? []),
                description: f.description ?? ""
            )

            return (
                booking: booking,
                room: room,
                dateText: BoardroomsAPI.shortDateText(from: dateInt)
            )
        }
        .sorted { ($0.booking.fields.date ?? 0) < ($1.booking.fields.date ?? 0) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {

                if displayBookings.isEmpty {
                    EmptyMyBookingCard()
                        .frame(height: 140)
                        .padding(.top, 16)
                } else {
                    ForEach(displayBookings, id: \.booking.id) { item in
                        RoomCard(
                            title: item.room.title,
                            floor: item.room.floor,
                            people: item.room.people,
                            tag: .date(item.dateText),
                            imageName: item.room.imageName,
                            imageURL: item.room.imageURL,
                            features: item.room.features
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func mapFacilitiesToFeatures(_ facilities: [String]) -> [RoomFeature] {
        let lower = facilities.map { $0.lowercased() }
        var out: [RoomFeature] = []
        if lower.contains(where: { $0.contains("wifi") }) { out.append(.wifi) }
        if lower.contains(where: { $0.contains("screen") || $0.contains("display") }) { out.append(.screen) }
        if lower.contains(where: { $0.contains("mic") }) { out.append(.mic) }
        if lower.contains(where: { $0.contains("control") }) { out.append(.control) }
        return out
    }
}


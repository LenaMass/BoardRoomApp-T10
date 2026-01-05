
import SwiftUI

struct BookingView: View {
    let bookings: [BookingData]
    let boardrooms: [BoardroomRecord]
    let onRefresh: () async -> Void

    init(bookings: [BookingData], boardrooms: [BoardroomRecord], onRefresh: @escaping () async -> Void = {}) {
        self.bookings = bookings
        self.boardrooms = boardrooms
        self.onRefresh = onRefresh
    }

    private var sortedBookings: [BookingData] {
        bookings.sorted { $0.fields.date < $1.fields.date }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {

                if sortedBookings.isEmpty {
                    EmptyState()
                        .padding(.top, 40)
                } else {
                    ForEach(sortedBookings) { b in
                        if let date = dateFromInt(b.fields.date),
                           let room = roomInfo(for: b) {

                            NavigationLink {
                                RoomDetailView(room: room, initialDate: date) {
                                    await onRefresh()
                                }
                            } label: {
                                RoomCard(
                                    title: room.title,
                                    floor: room.floor,
                                    people: room.people,
                                    tag: .date(shortDateText(from: date)),
                                    imageName: room.imageName,
                                    imageURL: room.imageURL,
                                    features: room.features
                                )
                                .frame(height: 122)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .navigationTitle("Bookings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func roomInfo(for booking: BookingData) -> RoomInfo? {
        guard let rec = boardrooms.first(where: { $0.id == booking.fields.boardroomID }),
              let f = rec.fields,
              let title = f.name,
              !title.isEmpty
        else { return nil }

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
}

struct EmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("No bookings yet")
                .font(.headline)

            Text("Once you book a room, it will appear here.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6)
    }
}

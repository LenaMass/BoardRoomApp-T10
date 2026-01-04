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
    let features: [RoomFeature]
    let description: String
}

// MARK: - Main View

struct BoardRoomsView: View {

    struct DayModel: Identifiable {
        let id = UUID()
        let day: String
        let weekDay: String
    }

    @State private var selectedDayIndex = 0
  //  @StateObject private var bookingVM = BookingViewModel()

    private let days: [DayModel] = [
        .init(day: "16", weekDay: "Thu"),
        .init(day: "19", weekDay: "Sun"),
        .init(day: "20", weekDay: "Mon"),
        .init(day: "21", weekDay: "Tue"),
        .init(day: "22", weekDay: "Wed"),
        .init(day: "23", weekDay: "Thu"),
        .init(day: "26", weekDay: "Sun"),
        .init(day: "27", weekDay: "Mon"),
        .init(day: "28", weekDay: "Tue")
    ]

    private let myRoom = RoomInfo(
        title: "Creative Space",
        floor: "Floor 5",
        people: "1",
        imageName: "room1",
        features: [.wifi],
        description:
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
    )

    private let rooms: [RoomInfo] = [
        RoomInfo(
            title: "Creative Space",
            floor: "Floor 5",
            people: "1",
            imageName: "room1",
            features: [.wifi],
            description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
        ),
        RoomInfo(
            title: "Ideation Room",
            floor: "Floor 3",
            people: "16",
            imageName: "room2",
            features: [.wifi, .screen],
            description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
        ),
        RoomInfo(
            title: "Inspiration Room",
            floor: "Floor 1",
            people: "18",
            imageName: "room3",
            features: [.wifi, .mic, .control],
            description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: - Banner (نفس التصميم الأصلي)
                    BannerView()
                        .padding(.top, 8)

                    // 🔥 هنا تشتغل الـ API بدون ما تغيّر شكل التصميم
                    // تقدرِ لاحقًا تستخدمِ bookingVM.records
                    // عشان تحدّدين إذا الغرفة متاحة أو لا حسب البيانات.
                    // مثال (مكانه مستقبلاً):
                    // let hasBookings = !bookingVM.records.isEmpty

                    // MARK: - My Booking

                    VStack(spacing: 12) {
                        HStack {
                            Text("My booking")
                                .font(.headline)
                            Spacer()
                            Text("See All")
                                .foregroundColor(Color.OR_1)
                        }

                        NavigationLink {
                            RoomDetailView(room: myRoom)
                        } label: {
                            RoomCard(
                                title: myRoom.title,
                                floor: myRoom.floor,
                                people: myRoom.people,
                                tag: .date("28 March"),
                                imageName: myRoom.imageName,
                                features: myRoom.features
                            )
                            .frame(height: 122)
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: - Calendar + Rooms

                    VStack(alignment: .leading, spacing: 16) {

                        Text("All bookings for March")
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
                                    }
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(rooms.indices, id: \.self) { i in
                                let r = rooms[i]

                                // هنا ممكن تربط حالة الغرفة مع الـ API لاحقاً
                                let status: RoomCard.Status = (i == 0) ? .available : .unavailable

                                NavigationLink {
                                    RoomDetailView(room: r)
                                } label: {
                                    RoomCard(
                                        title: r.title,
                                        floor: r.floor,
                                        people: r.people,
                                        tag: .status(status),
                                        imageName: r.imageName,
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
        }
        .onAppear {
           // bookingVM.fetchBookings()
        }
    }
}

// MARK: - Banner View

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
                    Button(action: {
                        print("Book now tapped")
                    }) {
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

// MARK: - Day Chip

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

// MARK: - Room Card

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
    var features: [RoomFeature] = []

    var body: some View {
        ZStack(alignment: .topTrailing) {

            HStack(spacing: 12) {

                Image(imageName)
                    .resizable()
                    .scaledToFill()
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

#Preview {
    BoardRoomsView()
}

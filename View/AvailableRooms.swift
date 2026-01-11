import SwiftUI

struct AvailableRoomsTodayView: View {
    let rooms: [RoomInfo]
    let isUnavailable: (RoomInfo) -> Bool
    let onChanged: (() async -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var availableRooms: [RoomInfo] {
        rooms.filter { !isUnavailable($0) }
    }

    var body: some View {
        ZStack {
            Color.screenBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Rooms Today")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blueButton)
                        .padding(.top, 8)

                    if availableRooms.isEmpty {
                        Text("No rooms available today.")
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(availableRooms.indices, id: \.self) { i in
                                let r = availableRooms[i]
                                NavigationLink {
                                    RoomDetailView(room: r, initialDate: Date(), onChanged: onChanged)
                                } label: {
                                    RoomCard(
                                        title: r.title,
                                        floor: r.floor,
                                        people: r.people,
                                        tag: .status(.available),
                                        imageName: r.imageName,
                                        imageURL: r.imageURL,
                                        features: r.features
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(Color.blueButton, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AvailableRoomsTodayView(
            rooms: [],
            isUnavailable: { _ in false },
            onChanged: nil
        )
    }
}



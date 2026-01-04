import SwiftUI

struct RoomDetailView: View {
    let room: RoomInfo?

    private let days: [(day: String, weekDay: String)] = [
        ("16", "Thu"),
        ("19", "Sun"),
        ("20", "Mon"),
        ("21", "Tue"),
        ("22", "Wed"),
        ("23", "Thu"),
        ("26", "Sun"),
        ("27", "Mon"),
        ("28", "Tue")
    ]

    @State private var selectedDayIndex = 1

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                Image(room?.imageName ?? "")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "location")
                        Text(room?.floor ?? "")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                        Text(room?.people ?? "")
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

                    Text(room?.description ?? "")
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
                        ForEach(room?.features ?? [], id: \.self) { feature in
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
                }
                .padding(.horizontal, 16)

                Button {
                    print("Booking tapped")
                } label: {
                    Text("Booking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.OR_1)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 60)
            }
        }
        .navigationTitle(room?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.blueButton, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    RoomDetailView(room: nil)
}

import SwiftUI

struct RoomDetailView: View {
    let room: RoomInfo
    let initialDate: Date
    let onChanged: (() async -> Void)?

    @AppStorage("employeeID") private var employeeID: String = ""

    @StateObject private var vm: RoomDetailViewModel

    init(room: RoomInfo, initialDate: Date, onChanged: (() async -> Void)? = nil) {
        self.room = room
        self.initialDate = initialDate
        self.onChanged = onChanged
        _vm = StateObject(wrappedValue: RoomDetailViewModel(room: room, initialDate: initialDate))
    }

    var body: some View {
        ZStack {
            Color.screenBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    Group {
                        if let urlStr = room.imageURL,
                           let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack { Color.white; ProgressView() }
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    Image(room.imageName).resizable().scaledToFill()
                                }
                            }
                        } else {
                            Image(room.imageName).resizable().scaledToFill()
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
                        Text("Description").font(.headline)
                        Text(room.description)
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Facilities").font(.headline)

                        HStack(spacing: 12) {
                            ForEach(room.features, id: \.self) { feature in
                                HStack(spacing: 6) {
                                    Image(systemName: feature.systemImageName)
                                    Text(feature.label).font(.subheadline)
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
                        Text("All bookings for \(vm.monthTitle)")
                            .font(.headline)

                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(vm.days.indices, id: \.self) { index in
                                    let d = vm.days[index]
                                    Button { vm.selectedDayIndex = index } label: {
                                        DayChip(day: d.day, weekDay: d.weekDay, isSelected: vm.selectedDayIndex == index)
                                            .opacity(vm.isLoading ? 0.6 : 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    if !vm.errorText.isEmpty {
                        Text(vm.errorText)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }

                    Button {
                        Task { await vm.bookSelectedDay(employeeID: employeeID) }
                    } label: {
                        Text(vm.isUnavailableSelectedDay ? "Unavailable" : "Booking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(vm.isUnavailableSelectedDay ? Color.gray : Color.OR_1)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .disabled(vm.isUnavailableSelectedDay || vm.isLoading)

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationTitle(room.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.blueButton, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.onAppearLoad() }
        .fullScreenCover(isPresented: $vm.showSuccess, onDismiss: {
            Task { if let onChanged { await onChanged() } }
        }) {
            BookingSuccessView(roomName: room.title, date: vm.successDate)
        }
    }
}


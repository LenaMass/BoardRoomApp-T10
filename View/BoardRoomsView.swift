import SwiftUI

struct BoardRoomsView: View {

@StateObject private var vm = BoardRoomsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.screenBG.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        BannerView()
                            .padding(.top, 8)

                        VStack(spacing: 12) {
                            HStack {
                                Text("My booking")
                                    .font(.headline)

                                Spacer()

                                NavigationLink {
                                    BookingView(
                                        bookings: vm.myBookings,
                                        boardrooms: vm.boardrooms,
                                        onChanged: {
                                            await vm.fetchData()
                                        }
                                    )
                                } label: {
                                    Text("See All")
                                        .foregroundColor(Color.OR_1)
                                }
                                .buttonStyle(.plain)
                            }

                            if let b = vm.nextMyBooking,
                               let dateInt = b.fields.date,
                               let bookedDate = BoardroomsAPI.dateFromInt(dateInt),
                               let room = vm.roomInfo(for: b) {

                                NavigationLink {
                                    RoomDetailView(room: room, initialDate: bookedDate) {
                                        await vm.fetchData()
                                    }
                                } label: {
                                    RoomCard(
                                        title: room.title,
                                        floor: room.floor,
                                        people: room.people,
                                        tag: .date(BoardroomsAPI.shortDateText(from: dateInt)),
                                        imageName: room.imageName,
                                        imageURL: room.imageURL,
                                        features: room.features
                                    )
                                    .frame(height: 122)
                                }
                                .buttonStyle(.plain)

                            } else {
                                EmptyMyBookingCard()
                                    .frame(height: 122)
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {

                            HStack {
                                Text("All bookings for \(vm.monthTitle)")
                                    .font(.headline)

                                Spacer()

                                if vm.isLoadingBookings {
                                    ProgressView()
                                } else {
                                    Text("Bookings this month: \(vm.bookingsCountThisMonth())")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            if !vm.bookingsError.isEmpty {
                                Text(vm.bookingsError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(vm.days.indices, id: \.self) { index in
                                        let d = vm.days[index]
                                        Button { vm.selectedDayIndex = index } label: {
                                            DayChip(day: d.day, weekDay: d.weekDay, isSelected: vm.selectedDayIndex == index)
                                        }
                                    }
                                }
                            }

                            VStack(spacing: 12) {
                                ForEach(vm.apiRooms.indices, id: \.self) { i in
                                    let r = vm.apiRooms[i]
                                    let unavailable = vm.isRoomUnavailable(r, on: vm.selectedDate)

                                    NavigationLink {
                                        RoomDetailView(room: r, initialDate: vm.selectedDate) {
                                            await vm.fetchData()
                                        }
                                    } label: {
                                        RoomCard(
                                            title: r.title,
                                            floor: r.floor,
                                            people: r.people,
                                            tag: .status(unavailable ? .unavailable : .available),
                                            imageName: r.imageName,
                                            imageURL: r.imageURL,
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
            }
            .navigationTitle("Board Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blueButton, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await vm.bootstrap() }
            .refreshable { await vm.fetchData() }
        }
    }
}


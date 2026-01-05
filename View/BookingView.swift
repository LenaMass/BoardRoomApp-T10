//import SwiftUI
//
//struct BookingsAPITesterView: View {
//    @State private var bookings: [BookingData] = []
//    @State private var statusMessage: String = "Ready"
//    @State private var isLoading = false
//
//    @State private var employeeIDInput: String = "recAngCB07LnodYvM"
//    @State private var boardroomIDInput: String = "rec4djvla4KsEXivl"
//    @State private var dateInput: String = "1737954445"
//    @State private var statusInput: String = "Confirmed"
//
//    @State private var selectedBookingID: String = ""
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 12) {
//
//                Text(statusMessage)
//                    .font(.caption)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//
//                if isLoading {
//                    ProgressView()
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//
//                Form {
//                    Section("Create (POST)") {
//                        TextField("employee_id", text: $employeeIDInput)
//                            .textInputAutocapitalization(.never)
//                        TextField("boardroom_id", text: $boardroomIDInput)
//                            .textInputAutocapitalization(.never)
//                        TextField("date (unix int)", text: $dateInput)
//                            .keyboardType(.numberPad)
//                        TextField("status", text: $statusInput)
//
//                        Button("POST Create Booking") {
//                            Task { await postBooking() }
//                        }
//                    }
//
//                    Section("Select a booking") {
//                        TextField("selected booking record id", text: $selectedBookingID)
//                            .textInputAutocapitalization(.never)
//                            .font(.caption)
//
//                        if selectedBookingID.isEmpty, let first = bookings.first?.id {
//                            Button("Use first booking id") {
//                                selectedBookingID = first
//                            }
//                        }
//                    }
//
//                    Section("Update (PATCH)") {
//                        Button("PATCH Update Status → Confirmed") {
//                            Task { await patchStatus("Confirmed") }
//                        }
//                        Button("PATCH Update Status → Cancelled") {
//                            Task { await patchStatus("Cancelled") }
//                        }
//                    }
//
//                    Section("Delete (DELETE)") {
//                        Button(role: .destructive) {
//                            Task { await deleteSelected() }
//                        } label: {
//                            Text("DELETE Selected Booking")
//                        }
//                    }
//                }
//
//                List(bookings) { b in
//                    Button {
//                        selectedBookingID = b.id
//                    } label: {
//                        VStack(alignment: .leading, spacing: 6) {
//                            Text(b.fields.status ?? "Unknown")
//                                .font(.headline)
//                            Text("id: \(b.id)")
//                                .font(.caption2)
//                                .foregroundStyle(.secondary)
//                            Text("employee: \(b.fields.employeeID)")
//                                .font(.caption2)
//                                .foregroundStyle(.secondary)
//                            Text("room: \(b.fields.boardroomID)")
//                                .font(.caption2)
//                                .foregroundStyle(.secondary)
//                            Text("date: \(b.fields.date)")
//                                .font(.caption2)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Bookings API Tester")
//            .toolbar {
//                Button("GET Refresh") {
//                    Task { await fetch() }
//                }
//            }
//            .task { await fetch() }
//        }
//    }
//
//    @MainActor
//    private func fetch() async {
//        isLoading = true
//        statusMessage = "Loading..."
//        defer { isLoading = false }
//
//        do {
//            bookings = try await BookingData.getAllBookings()
//            statusMessage = "GET ✅ \(bookings.count) bookings"
//            if selectedBookingID.isEmpty {
//                selectedBookingID = bookings.first?.id ?? ""
//            }
//        } catch {
//            statusMessage = "GET ❌ \(error)"
//        }
//    }
//
//    @MainActor
//    private func postBooking() async {
//        isLoading = true
//        statusMessage = "Posting..."
//        defer { isLoading = false }
//
//        guard let date = Int(dateInput.trimmingCharacters(in: .whitespacesAndNewlines)) else {
//            statusMessage = "POST ❌ date must be an Int"
//            return
//        }
//
//        do {
//            let created = try await BookingData.createBooking(
//                status: statusInput,
//                employeeID: employeeIDInput,
//                boardroomID: boardroomIDInput,
//                date: date
//            )
//            statusMessage = "POST ✅ created \(created.id)"
//            await fetch()
//        } catch {
//            statusMessage = "POST ❌ \(error)"
//        }
//    }
//
//    @MainActor
//    private func patchStatus(_ newStatus: String) async {
//        isLoading = true
//        statusMessage = "Updating..."
//        defer { isLoading = false }
//
//        guard !selectedBookingID.isEmpty else {
//            statusMessage = "PATCH ❌ select a booking id"
//            return
//        }
//
//        do {
//            _ = try await BookingData.updateBooking(
//                id: selectedBookingID,
//                status: newStatus
//            )
//            statusMessage = "PATCH ✅ updated \(selectedBookingID)"
//            await fetch()
//        } catch {
//            statusMessage = "PATCH ❌ \(error)"
//        }
//    }
//
//    @MainActor
//    private func deleteSelected() async {
//        isLoading = true
//        statusMessage = "Deleting..."
//        defer { isLoading = false }
//
//        guard !selectedBookingID.isEmpty else {
//            statusMessage = "DELETE ❌ select a booking id"
//            return
//        }
//
//        do {
//            let ok = try await BookingData.deleteBooking(id: selectedBookingID)
//            statusMessage = ok ? "DELETE ✅ deleted \(selectedBookingID)" : "DELETE ❌ not deleted"
//            selectedBookingID = ""
//            await fetch()
//        } catch {
//            statusMessage = "DELETE ❌ \(error)"
//        }
//    }
//}
//
//#Preview {
//    BookingsAPITesterView()
//}
//

import SwiftUI

struct BookingSuccessView: View {
    let roomName: String
    let date: Date

    @Environment(\.dismiss) private var dismiss

    private var messageText: String {
        let cal = BoardroomsAPI.gregorianCalendar

        let weekday = DateFormatter()
        weekday.calendar = cal
        weekday.locale = Locale(identifier: "en_US_POSIX")
        weekday.timeZone = .current
        weekday.dateFormat = "EEEE"

        let full = DateFormatter()
        full.calendar = cal
        full.locale = Locale(identifier: "en_US_POSIX")
        full.timeZone = .current
        full.dateFormat = "MMMM d, yyyy"

        return "Your booking for \(roomName) on \(weekday.string(from: date)),\n\(full.string(from: date)) is confirmed."
    }

    var body: some View {
        ZStack {
            Color.screenBG
                .ignoresSafeArea()

            VStack(spacing: 0) {

                ZStack {
                    Image("BackG")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 420)
                        .clipped()

                    Image("Circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 253, height: 253)
                }
                .frame(height: 420)

                VStack(spacing: 14) {
                    Text("Booking Success!")
                        .font(.system(size: 32, weight: .bold))

                    Text(messageText)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.OR_1)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 26)
                }
                .padding(.top, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    BookingSuccessView(roomName: "Ideation Room", date: Date())
}


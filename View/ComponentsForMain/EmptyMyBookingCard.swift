import SwiftUI

struct EmptyMyBookingCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6)

            VStack(spacing: 8) {
                Text("No bookings made yet")
                    .font(.headline)

                Text("Book a room and it will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 18)
        }
    }
}

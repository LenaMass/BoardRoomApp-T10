import SwiftUI
struct BookingSuccessView: View {

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 0.94)
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

                    Text("Your booking for Ideation Room on Sunday,\nMarch 19, 2023 is confirmed.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Spacer()

                    Button(action: {}) {
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

#Preview{
    BookingSuccessView()
}

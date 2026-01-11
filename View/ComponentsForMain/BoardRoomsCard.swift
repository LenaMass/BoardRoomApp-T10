import SwiftUI

struct BoardRoomsCard: View {
    var onBookNow: () -> Void = {}

    var body: some View {
        ZStack {

            Circle()
                .fill(Color.blueButton)
                .frame(width: 75, height: 70)
                .offset(x: -169, y: 77)

            Image("board1")
                .resizable()

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("All board rooms")
                        .foregroundColor(.white)
                        .font(.system(size: 15))

                    Text("Available today")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, -40)

                Spacer()

                VStack {
                    Spacer()
                    Button(action: onBookNow) {
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
                    .padding(.horizontal)
                    .padding(-10)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 138)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    BoardRoomsCard()
}


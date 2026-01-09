import SwiftUI

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
                    Button(action: {}) {
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
        .frame(maxWidth: .infinity)
        .frame(height: 138)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

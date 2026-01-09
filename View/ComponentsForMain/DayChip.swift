import SwiftUI

struct DayChip: View {
    let day: String
    let weekDay: String
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(weekDay)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(day)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.OR_1 : .clear)
                        .overlay(
                            Circle()
                                .stroke(.gray.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                )
        }
    }
}

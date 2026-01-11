import SwiftUI

struct CalendarDayChip: View {
    let day: String
    let weekDay: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(weekDay)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(day)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.OR_1 : .white)
                        .overlay(
                            Circle()
                                .stroke(.gray.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                )
        }
    }
    
}


#Preview {
    ZStack {
        Color.screenBG.ignoresSafeArea()
        HStack(spacing: 12) {
            CalendarDayChip(day: "11", weekDay: "Sun", isSelected: true)
            CalendarDayChip(day: "12", weekDay: "Mon", isSelected: false)
        }
        .padding()
    }
}

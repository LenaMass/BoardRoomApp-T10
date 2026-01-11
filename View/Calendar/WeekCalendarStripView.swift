import SwiftUI

struct WeekCalendarStripView: View {
    let title: String
    let days: [CalendarDay]
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(days.indices, id: \.self) { index in
                        Button {
                            selectedIndex = index
                        } label: {
                            CalendarDayChip(
                                day: days[index].dayNumberText,
                                weekDay: days[index].weekdayShortText,
                                isSelected: selectedIndex == index
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    struct PreviewWrap: View {
        @State private var selected = 0
        private let days = WeekCalendarProvider.makeWeekStartingToday()
        private let title = WeekCalendarProvider.weekTitle()

        var body: some View {
            ZStack {
                Color.screenBG.ignoresSafeArea()
                WeekCalendarStripView(title: title, days: days, selectedIndex: $selected)
                    .padding()
            }
        }
    }

    return PreviewWrap()
}


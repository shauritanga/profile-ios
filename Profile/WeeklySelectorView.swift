import SwiftUI

struct WeekSelectorView: View {

    @Binding var selectedDay: Int

    /// Seven real days centered on today (3 before, today, 3 after).
    let days: [DayItem] = {
        let calendar = Calendar.current
        let today = Date()
        let nameFormatter = DateFormatter()
        nameFormatter.dateFormat = "EEE"
        return (-3...3).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return DayItem(
                name: nameFormatter.string(from: date),
                number: String(calendar.component(.day, from: date))
            )
        }
    }()

    var body: some View {

        HStack {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in

                Button {
                    selectedDay = index
                } label: {

                    VStack(spacing: 7) {

                        Text(day.name)
                            .font(.system(size: 14))

                        Text(day.number)
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(
                        selectedDay == index
                        ? .white
                        : .primary
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(
                        selectedDay == index
                        ? Color(red: 0.01, green: 0.12, blue: 0.16)
                        : Color.clear
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

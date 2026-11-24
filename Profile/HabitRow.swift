import SwiftUI
struct HabitRow: View {

    @Binding var habit: Habit

    var body: some View {
        HStack(spacing: 16) {

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .frame(width: 52, height: 52)

                Text(habit.icon)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.title)
                    .font(.system(size: 18, weight: .semibold))

                Text(habit.timeText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                habit.completed.toggle()
            } label: {
                Image(
                    systemName:
                        habit.completed
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.system(size: 28))
                .foregroundStyle(
                    habit.completed
                    ? Color.green
                    : Color.gray
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

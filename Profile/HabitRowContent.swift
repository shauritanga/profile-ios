import SwiftUI

struct HabitRowContent: View {

    let habit: Habit
    var onToggle: () -> Void = {}

    var body: some View {

        HStack(spacing: 13) {

            Button(action: onToggle) { statusIcon }
                .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 46, height: 46)

                Text(habit.icon)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 3) {

                Text(habit.title)
                    .font(.system(size: 17, weight: .medium))

                Text(habit.timeText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var statusIcon: some View {

        switch habit.status {

        case .completed:

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.green)
                .clipShape(Circle())

        case .skipped:

            Image(systemName: "minus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())

        case .pending:

            Circle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 30, height: 30)
        }
    }
}

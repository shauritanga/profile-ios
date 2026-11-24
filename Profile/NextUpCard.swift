import SwiftUI

struct NextUpCard: View {

    @EnvironmentObject private var store: HabitStore

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Next up")
                .font(.system(size: 22, weight: .bold))

            if let habit = store.nextUp {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 48, height: 48)

                    Text(habit.icon)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.system(size: 18, weight: .medium))

                    Text(habit.timeText)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    store.setStatus(.completed, for: habit)
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                }
            }
            } else {
                Text(store.habits.isEmpty ? "Add a habit to get started" : "All done for today 🎉")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Color.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 25)
        )
    }
}

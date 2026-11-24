import SwiftUI

struct HabitsCard: View {

    @Binding var selectedFilter: String

    let filters: [String]

    @EnvironmentObject private var store: HabitStore

    private var habits: [Habit] {
        selectedFilter == "All"
            ? store.sortedHabits
            : store.sortedHabits.filter { $0.period.rawValue == selectedFilter }
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Today's habits")
                .font(.system(size: 23, weight: .bold))

            filterBar

            if habits.isEmpty {
                Text("No habits here yet. Tap + to add one.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }

            VStack(spacing: 0) {
                ForEach(habits) { habit in

                    HabitRowContent(habit: habit) {
                        store.cycleStatus(for: habit)
                    }

                    if habit.id != habits.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 25)
        )
    }

    private var filterBar: some View {

        HStack(spacing: 10) {

            ForEach(filters, id: \.self) { filter in

                Button {
                    selectedFilter = filter
                } label: {

                    Text(filter)
                        .font(.system(size: 14))
                        .foregroundStyle(
                            selectedFilter == filter
                            ? .white
                            : .primary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            selectedFilter == filter
                            ? Color(red: 0.01, green: 0.12, blue: 0.16)
                            : Color(.systemGray6)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

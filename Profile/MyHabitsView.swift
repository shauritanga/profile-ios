import SwiftUI

struct MyHabitsView: View {
    
    
    @EnvironmentObject private var store: HabitStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Summary
                HabitSummaryCard(
                    completed: store.completedCount,
                    total: store.todaysHabits.count
                )
                
                // MARK: - Today's Habits
                VStack(alignment: .leading, spacing: 14) {
                    
                    Text("Today's Habits")
                        .font(.system(size: 22, weight: .bold))
                    
                    if store.habits.isEmpty {
                        Text("No habits yet. Tap + to add your first one.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    }

                    ForEach($store.habits) { $habit in
                        HabitRow(habit: $habit)
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.delete(habit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle("My Habits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

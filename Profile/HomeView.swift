import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedDay = 3
    @State private var selectedFilter = "All"

    let filters = ["All", "Morning", "Afternoon", "Evening"]

    var body: some View {
        ZStack(alignment: .bottom) {

            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    headerView

                    WeekSelectorView(
                        selectedDay: $selectedDay
                    )

                    ProgressCard(
                        completed: store.completedCount,
                        skipped: store.skippedCount,
                        left: store.pendingCount
                    )

                    NextUpCard()

                    HabitsCard(
                        selectedFilter: $selectedFilter,
                        filters: filters
                    )

                    Spacer()
                        .frame(height: 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            //BottomBar()
        }
    }
}


extension HomeView {

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "morning" : (hour < 18 ? "afternoon" : "evening")
        let name = settings.firstName
        return name.isEmpty ? "Good \(part)" : "Good \(part), \(name)"
    }

    private var headerView: some View {
        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 5) {

                Text(greeting)
                    .font(.system(size: 20, weight: .bold))

                Text("Let's make today count")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Text("\(store.streak)")
                    .fontWeight(.semibold)

                Text("🔥")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.card)
            .clipShape(Capsule())
        }
    }
}

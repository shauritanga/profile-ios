import SwiftUI

struct MainView: View {

    @State private var selectedTab = 0
    @EnvironmentObject private var store: HabitStore
    @State private var showAddHabit = false

    var body: some View {

        ZStack(alignment: .bottom) {

            Group {
                switch selectedTab {

                case 0:
                    HomeView()

                case 1:
                    ExploreView()
                case 2:
                   StatisticsView()

                case 3:
                    ProfileView()

                default:
                    HomeView()
                }
            }
        }
        // As a safe-area inset (not an overlay) so scrolling content, including pushed screens,
        // always stops above the bar.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar(
                selectedTab: $selectedTab,
                showAddHabit: $showAddHabit
            )
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitView { newHabit in
                store.add(newHabit)
            }
        }
    }
}

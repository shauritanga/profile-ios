import SwiftUI
struct BottomBar: View {

    @Binding var selectedTab: Int
    @Binding var showAddHabit: Bool

    var body: some View {

        HStack {

            tabIcon(
                "house.fill",
                tab: 0
            )

            Spacer()

            tabIcon(
                "safari",
                tab: 1
            )

            Spacer()

            Button {
                showAddHabit = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        Color(
                            red: 0.01,
                            green: 0.12,
                            blue: 0.16
                        )
                    )
                    .clipShape(Circle())
            }

            Spacer()

            tabIcon(
                "chart.line.uptrend.xyaxis",
                tab: 2
            )

            Spacer()

            tabIcon(
                "person",
                tab: 3
            )
        }
        .padding(.horizontal, 34)
        .padding(.top, 15)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }

    private func tabIcon(
        _ icon: String,
        tab: Int
    ) -> some View {

        Button {
            selectedTab = tab
        } label: {
            Image(systemName: icon)
                .font(.system(size: 23))
                .foregroundStyle(
                    selectedTab == tab
                    ? Color.blue
                    : Color.primary
                )
        }
    }
}

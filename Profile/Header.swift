import SwiftUI

extension HomeView {

    private var headerView: some View {
        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 5) {

                Text("Good morning, Olivia")
                    .font(.system(size: 30, weight: .bold))

                Text("Let's make today count")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Text("12")
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

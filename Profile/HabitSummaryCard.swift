import SwiftUI

struct HabitSummaryCard: View {

    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Today's Progress")
                        .font(.system(size: 20, weight: .bold))

                    Text("\(completed) of \(total) habits completed")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 22, weight: .bold))
            }

            ProgressView(value: progress)
                .tint(.green)
        }
        .padding(20)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

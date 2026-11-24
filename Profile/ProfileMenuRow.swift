import SwiftUI

struct ProfileMenuRow: View {

    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 18) {

            Image(systemName: icon)
                .font(.system(size: 23))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 18, weight: .medium))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 20)
        .frame(height: 72)
        .contentShape(Rectangle())
    }
}

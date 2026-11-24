import SwiftUI

struct ProgressCard: View {

    let completed: Int
    let skipped: Int
    let left: Int

    private var total: Int { completed + skipped + left }

    var body: some View {
        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 14) {

                Text("Today's progress")
                    .font(.system(size: 16, weight: .bold))

                progressItem(
                    color: Color(red: 0.42, green: 0.80, blue: 0.27),
                    text: "\(completed) completed"
                )

                progressItem(
                    color: Color(red: 0.12, green: 0.31, blue: 0.80),
                    text: "\(skipped) skipped"
                )

                progressItem(
                    color: .gray.opacity(0.4),
                    text: "\(left) left"
                )
            }

            Spacer()

            GeometryReader { geo in
                let radius = min(geo.size.width / 2, geo.size.height / 1.5)
                ZStack {
                    ForEach(segments.indices, id: \.self) { i in
                        let seg = segments[i]
                        SectorShape(start: seg.start, end: seg.end, thickness: 26, corner: 4)
                            .fill(seg.color)
                            .overlay(
                                SectorShape(start: seg.start, end: seg.end, thickness: 26, corner: 4)
                                    .stroke(seg.color, style: StrokeStyle(lineWidth: 8, lineJoin: .round))
                            )
                    }

                    VStack(spacing: 3) {
                        Text("\(completed) / \(total)")
                            .font(.system(size: 18, weight: .bold))

                        Text("completed")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .position(x: geo.size.width / 2, y: radius + 6)
                }
            }
            .frame(width: 164)
        }
        .padding(22)
        .background(Color.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 25)
        )
    }

    private struct Segment {
        let start: Angle
        let end: Angle
        let color: Color
    }

    /// Semi-circular arc split into completed / skipped / left with small gaps.
    private var segments: [Segment] {
        let all: [(Int, Color)] = [
            (completed, Color(red: 0.42, green: 0.80, blue: 0.27)),
            (skipped, Color(red: 0.12, green: 0.31, blue: 0.80)),
            (left, Color(white: 0.84))
        ]
        let counts = total == 0 ? [(1, Color(white: 0.84))] : all.filter { $0.0 > 0 }
        let total = Double(counts.reduce(0) { $0 + $1.0 })
        let gap = 7.0
        let span = 240.0 - gap * Double(counts.count - 1)
        var angle = 150.0
        return counts.map { count, color in
            let sweep = span * Double(count) / total
            defer { angle += sweep + gap }
            return Segment(start: .degrees(angle), end: .degrees(angle + sweep), color: color)
        }
    }

    private func progressItem(
        color: Color,
        text: String
    ) -> some View {

        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color(white: 0.3))
        }
    }
}

/// Annular sector whose outer radius fills the rect's width / height (arc spans 240°,
/// so the arc is `1.5 * radius` tall). Top touches rect top, legs end at 1.5 * radius.
private struct SectorShape: Shape {
    var start: Angle
    var end: Angle
    var thickness: CGFloat
    var corner: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width / 2, rect.height / 1.5)
        let c = CGPoint(x: rect.midX, y: rect.minY + radius)
        let outer = radius - corner
        let inner = radius - thickness + corner
        // Inset the angular edges too, so the round-joined stroke doesn't eat the gap.
        let mid = radius - thickness / 2
        let inset = Angle(radians: Double(corner / mid))
        let a0 = start + inset
        let a1 = end - inset
        var p = Path()
        p.addArc(center: c, radius: outer, startAngle: a0, endAngle: a1, clockwise: false)
        p.addArc(center: c, radius: inner, startAngle: a1, endAngle: a0, clockwise: true)
        p.closeSubpath()
        return p
    }
}

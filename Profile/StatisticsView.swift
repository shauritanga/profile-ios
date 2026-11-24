import SwiftUI

struct StatisticsView: View {

    @EnvironmentObject private var store: HabitStore

    @State private var rangeDays = 7
    @State private var offset = 0   // 0 = current period, -1 = previous, ...

    private let ink = Color(red: 0.01, green: 0.12, blue: 0.16)
    private let blue = Color(red: 0.12, green: 0.31, blue: 0.80)
    private let green = Color(red: 0.42, green: 0.80, blue: 0.27)

    // MARK: - Period

    /// 7 days = calendar week (Mon–Sun); 30 days = a rolling 30-day window ending today.
    private var days: [Date] {
        let cal = Calendar(identifier: .iso8601)
        let today = cal.startOfDay(for: Date())
        if rangeDays == 7 {
            let monday = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            let start = cal.date(byAdding: .day, value: 7 * offset, to: monday) ?? monday
            return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        }
        let end = cal.date(byAdding: .day, value: 30 * offset, to: today) ?? today
        return (0..<30).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: end) }
    }

    private var rangeText: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        guard let first = days.first, let last = days.last else { return "" }
        return "\(f.string(from: first)) - \(f.string(from: last))"
    }

    private var title: String {
        if rangeDays == 7 { return offset == 0 ? "This Week" : "Week" }
        return offset == 0 ? "Last 30 Days" : "30 Days"
    }

    private var canGoForward: Bool { offset < 0 }

    // MARK: - Data

    private var points: [(index: Int, value: Double)] {
        days.enumerated().compactMap { i, d in
            store.stats(on: d).map { (i, $0.rate) }
        }
    }

    private var overall: HabitStore.DayStats { store.stats(over: days) }

    private var consistency: Double { overall.rate }

    /// Of the habits you acted on, how many you completed instead of skipping.
    private var discipline: Double {
        let acted = overall.completed + overall.skipped
        return acted == 0 ? 0 : Double(overall.completed) / Double(acted)
    }

    private var morningRate: Double {
        store.stats(over: days, habits: store.habits.filter { $0.period == .morning }).rate
    }

    private func rate(for habit: Habit) -> Double {
        store.stats(over: days, habits: [habit]).rate
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    rangePicker
                    chartSection
                    metricsCard
                    habitsCard
                    Spacer().frame(height: 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Progress")
                .font(.system(size: 30, weight: .bold))

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

    private var rangePicker: some View {
        Menu {
            Button("7 Days") { rangeDays = 7; offset = 0 }
            Button("30 Days") { rangeDays = 30; offset = 0 }
        } label: {
            HStack {
                Text("\(rangeDays) Days")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 22)
            .frame(height: 58)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var chartSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .bold))

                Spacer()

                Button { offset -= 1 } label: {
                    Image(systemName: "chevron.left")
                }

                Text(rangeText)
                    .font(.system(size: 16))
                    .frame(minWidth: 120)

                Button { offset += 1 } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
                .opacity(canGoForward ? 1 : 0.3)
            }
            .foregroundStyle(.primary)

            LineChart(
                points: points,
                count: days.count,
                labels: xLabels,
                color: blue
            )
            .frame(height: 260)
        }
    }

    private var xLabels: [(index: Int, text: String)] {
        let cal = Calendar.current
        if rangeDays == 7 {
            let f = DateFormatter()
            f.dateFormat = "EEE"
            return days.enumerated().map { ($0, f.string(from: $1)) }
        }
        return days.enumerated().compactMap { i, d in
            i % 6 == 0 || i == days.count - 1 ? (i, String(cal.component(.day, from: d))) : nil
        }
    }

    private var metricsCard: some View {
        VStack(spacing: 0) {
            metricRow("Morning Routine", value: morningRate)
            Divider()
            metricRow("Consistency", value: consistency)
            Divider()
            metricRow("Discipline", value: discipline)
        }
        .padding(.horizontal, 20)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func metricRow(_ name: String, value: Double) -> some View {
        HStack(spacing: 14) {
            Text(name)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)

            ProgressBar(value: value, color: green)
                .frame(width: 130, height: 8)

            Text("\(Int((value * 100).rounded()))%")
                .font(.system(size: 17))
                .frame(width: 48, alignment: .trailing)
        }
        .frame(height: 64)
    }

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Habits")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 8)

            if store.habits.isEmpty {
                Text("Add a habit to see its progress here.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }

            let sorted = store.habits.sorted { $0.startMinutes < $1.startMinutes }
            ForEach(sorted) { habit in
                HStack(spacing: 14) {
                    Text(habit.icon)
                        .font(.system(size: 22))
                        .frame(width: 48, height: 48)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())

                    Text(habit.title)
                        .font(.system(size: 18))

                    Spacer()

                    Text("\(Int((rate(for: habit) * 100).rounded()))%")
                        .font(.system(size: 17))
                }
                .padding(.vertical, 8)

                if habit.id != sorted.last?.id {
                    Divider().padding(.leading, 62)
                }
            }
        }
        .padding(20)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Components

private struct ProgressBar: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(white: 0.9))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
    }
}

/// Smooth area chart, 0–100 %, with dashed grid like the design.
private struct LineChart: View {

    let points: [(index: Int, value: Double)]
    let count: Int
    let labels: [(index: Int, text: String)]
    let color: Color

    private let yLabels = [100, 75, 50, 25, 0]
    private let leftInset: CGFloat = 40
    private let bottomInset: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            let plot = CGRect(
                x: leftInset, y: 6,
                width: geo.size.width - leftInset - 4,
                height: geo.size.height - bottomInset - 6
            )

            ZStack(alignment: .topLeading) {
                grid(in: plot)
                curve(in: plot)

                ForEach(yLabels, id: \.self) { v in
                    Text("\(v)%")
                        .font(.system(size: 12))
                        .position(x: leftInset / 2 - 2, y: y(Double(v) / 100, in: plot))
                }

                ForEach(labels, id: \.index) { item in
                    Text(item.text)
                        .font(.system(size: 13))
                        .position(x: x(item.index, in: plot), y: plot.maxY + 16)
                }

                if points.isEmpty {
                    Text("No data yet")
                        .foregroundStyle(.secondary)
                        .position(x: plot.midX, y: plot.midY)
                }
            }
        }
    }

    private func x(_ index: Int, in plot: CGRect) -> CGFloat {
        count <= 1 ? plot.midX : plot.minX + plot.width * CGFloat(index) / CGFloat(count - 1)
    }

    private func y(_ value: Double, in plot: CGRect) -> CGFloat {
        plot.maxY - plot.height * CGFloat(value)
    }

    private func grid(in plot: CGRect) -> some View {
        Path { p in
            for v in yLabels {
                let yy = y(Double(v) / 100, in: plot)
                p.move(to: CGPoint(x: plot.minX, y: yy))
                p.addLine(to: CGPoint(x: plot.maxX, y: yy))
            }
            for l in labels {
                let xx = x(l.index, in: plot)
                p.move(to: CGPoint(x: xx, y: plot.minY))
                p.addLine(to: CGPoint(x: xx, y: plot.maxY))
            }
        }
        .stroke(color.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
    }

    @ViewBuilder
    private func curve(in plot: CGRect) -> some View {
        let pts = points.map { CGPoint(x: x($0.index, in: plot), y: y($0.value, in: plot)) }

        if pts.count == 1, let only = pts.first {
            Circle().fill(color).frame(width: 10, height: 10).position(only)
        } else if pts.count > 1 {
            let line = Path { p in
                p.move(to: pts[0])
                for i in 1..<pts.count {
                    let a = pts[i - 1], b = pts[i]
                    let midX = (a.x + b.x) / 2
                    p.addCurve(to: b, control1: CGPoint(x: midX, y: a.y), control2: CGPoint(x: midX, y: b.y))
                }
            }

            line
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            Path { p in
                p.addPath(line)
                p.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: plot.maxY))
                p.addLine(to: CGPoint(x: pts[0].x, y: plot.maxY))
                p.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.45), color.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
    }
}

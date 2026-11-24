import SwiftUI
import UIKit

/// Single source of truth for habits, persisted to UserDefaults.
final class HabitStore: ObservableObject {

    @Published var habits: [Habit] {
        didSet { save() }
    }

    private let key = "habits.v3"
    private let recordsKey = "habits.records.v1"
    private let lastDayKey = "habits.lastDay"

    /// History: day ("yyyy-MM-dd") -> habit id -> status. Pending is never stored.
    private var records: [String: [String: HabitStatus]] = [:]

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = saved
        } else {
            habits = []
        }
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let saved = try? JSONDecoder().decode([String: [String: HabitStatus]].self, from: data) {
            records = saved
        }
        rolloverIfNeeded()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.rolloverIfNeeded() }
    }

    /// Deletes every habit and all history.
    func eraseAll() {
        habits = []
        records = [:]
        saveRecords()
        objectWillChange.send()
    }

    // MARK: - Days

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    /// A new day starts with every habit pending; yesterday's results live on in `records`.
    private func rolloverIfNeeded() {
        let today = Self.dayKey(Date())
        guard UserDefaults.standard.string(forKey: lastDayKey) != today else { return }
        for i in habits.indices { habits[i].status = .pending }
        UserDefaults.standard.set(today, forKey: lastDayKey)
        objectWillChange.send()
    }

    // MARK: - History / statistics

    struct DayStats {
        var scheduled = 0
        var completed = 0
        var skipped = 0
        var rate: Double { scheduled == 0 ? 0 : Double(completed) / Double(scheduled) }
    }

    private func status(of habit: Habit, on date: Date) -> HabitStatus {
        records[Self.dayKey(date)]?[habit.id.uuidString] ?? .pending
    }

    private func existed(_ habit: Habit, on date: Date) -> Bool {
        guard let created = habit.createdAt else { return true }
        return Calendar.current.startOfDay(for: created) <= Calendar.current.startOfDay(for: date)
    }

    /// Stats for a day, or nil if it is in the future or nothing was scheduled.
    func stats(on date: Date, habits subset: [Habit]? = nil) -> DayStats? {
        guard date <= Date() else { return nil }
        let list = (subset ?? habits).filter { $0.occurs(on: date) && existed($0, on: date) }
        guard !list.isEmpty else { return nil }
        var out = DayStats()
        for h in list {
            out.scheduled += 1
            switch status(of: h, on: date) {
            case .completed: out.completed += 1
            case .skipped: out.skipped += 1
            case .pending: break
            }
        }
        return out
    }

    /// Summed stats over a set of days.
    func stats(over days: [Date], habits subset: [Habit]? = nil) -> DayStats {
        days.compactMap { stats(on: $0, habits: subset) }.reduce(into: DayStats()) {
            $0.scheduled += $1.scheduled
            $0.completed += $1.completed
            $0.skipped += $1.skipped
        }
    }

    /// Consecutive days (ending today, or yesterday if nothing is done yet today) with at least one completed habit.
    var streak: Int {
        let cal = Calendar.current
        func done(_ d: Date) -> Bool {
            (records[Self.dayKey(d)] ?? [:]).values.contains(.completed)
        }
        var day = Date()
        if !done(day) { day = cal.date(byAdding: .day, value: -1, to: day) ?? day }
        var count = 0
        while done(day), count < 3650 {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    /// Habits scheduled for today (based on each habit's repeat days).
    var todaysHabits: [Habit] { habits.filter { $0.occurs(on: Date()) } }

    var completedCount: Int { todaysHabits.filter { $0.status == .completed }.count }
    var skippedCount: Int { todaysHabits.filter { $0.status == .skipped }.count }
    var pendingCount: Int { todaysHabits.filter { $0.status == .pending }.count }

    /// Today's habits ordered by start time, earliest first.
    var sortedHabits: [Habit] { todaysHabits.sorted { $0.startMinutes < $1.startMinutes } }

    /// First pending habit whose time is still ahead; falls back to the earliest pending one.
    var nextUp: Habit? {
        let now = Habit.minutes(from: Date())
        let pending = sortedHabits.filter { $0.status == .pending }
        return pending.first { $0.startMinutes >= now } ?? pending.first
    }

    func add(_ habit: Habit) {
        habits.append(habit)
    }

    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }

    func setStatus(_ status: HabitStatus, for habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[i].status = status
        let today = Self.dayKey(Date())
        if status == .pending {
            records[today]?[habit.id.uuidString] = nil
        } else {
            records[today, default: [:]][habit.id.uuidString] = status
        }
        saveRecords()
        objectWillChange.send()
    }

    /// Tap cycle: pending -> completed -> skipped -> pending.
    func cycleStatus(for habit: Habit) {
        switch habit.status {
        case .pending: setStatus(.completed, for: habit)
        case .completed: setStatus(.skipped, for: habit)
        case .skipped: setStatus(.pending, for: habit)
        }
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

import Foundation

enum HabitPeriod: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
}

struct Habit: Identifiable, Codable, Equatable {
    var id = UUID()

    var title: String
    var icon: String
    /// Minutes since midnight.
    var startMinutes: Int
    var endMinutes: Int?
    /// Calendar weekdays (1 = Sunday ... 7 = Saturday). Empty means every day.
    var repeatDays: [Int] = []
    var status: HabitStatus = .pending
    /// nil for habits saved before this field existed (treated as always having existed).
    var createdAt: Date? = Date()

    var completed: Bool {
        get { status == .completed }
        set { status = newValue ? .completed : .pending }
    }

    /// Derived from the start time: before 12:00 morning, until 17:00 afternoon, then evening.
    var period: HabitPeriod {
        switch startMinutes {
        case ..<720: return .morning
        case ..<1020: return .afternoon
        default: return .evening
        }
    }

    /// e.g. "7:30 am" or "8:00–8:20 am"
    var timeText: String {
        guard let end = endMinutes else { return Self.format(startMinutes, withSuffix: true) }
        let sameSuffix = (startMinutes < 720) == (end < 720)
        return "\(Self.format(startMinutes, withSuffix: !sameSuffix))–\(Self.format(end, withSuffix: true))"
    }

    func occurs(on date: Date) -> Bool {
        repeatDays.isEmpty || repeatDays.contains(Calendar.current.component(.weekday, from: date))
    }

    /// "Every day", "Weekdays", or e.g. "Mon, Thu".
    static func repeatText(_ days: Set<Int>) -> String {
        if days.isEmpty || days.count == 7 { return "Every day" }
        let order = [2, 3, 4, 5, 6, 7, 1]
        let names = order.filter { days.contains($0) }.map { Calendar.current.shortWeekdaySymbols[$0 - 1] }
        return names.joined(separator: ", ")
    }

    static func format(_ minutes: Int, withSuffix: Bool) -> String {
        let h24 = (minutes / 60) % 24
        let m = minutes % 60
        let h12 = h24 % 12 == 0 ? 12 : h24 % 12
        let base = "\(h12):" + String(format: "%02d", m)
        return withSuffix ? base + (h24 < 12 ? " am" : " pm") : base
    }

    static func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

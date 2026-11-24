import SwiftUI
import UIKit
import UserNotifications
import LocalAuthentication

extension Color {
    /// White in light mode, elevated dark gray in dark mode.
    static let card = Color(.secondarySystemGroupedBackground)
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Profile details and app preferences, persisted to UserDefaults.
final class AppSettings: ObservableObject {

    private let defaults = UserDefaults.standard

    @Published var name: String { didSet { defaults.set(name, forKey: "profile.name") } }
    @Published var email: String { didSet { defaults.set(email, forKey: "profile.email") } }
    @Published var avatar: UIImage? {
        didSet { defaults.set(avatar?.jpegData(compressionQuality: 0.8), forKey: "profile.avatar") }
    }
    @Published var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: "settings.appearance") } }
    @Published var remindersEnabled: Bool { didSet { defaults.set(remindersEnabled, forKey: "settings.reminders") } }
    @Published var appLockEnabled: Bool { didSet { defaults.set(appLockEnabled, forKey: "settings.appLock") } }

    init() {
        name = defaults.string(forKey: "profile.name") ?? ""
        email = defaults.string(forKey: "profile.email") ?? ""
        avatar = defaults.data(forKey: "profile.avatar").flatMap(UIImage.init(data:))
        appearance = Appearance(rawValue: defaults.string(forKey: "settings.appearance") ?? "") ?? .system
        remindersEnabled = defaults.bool(forKey: "settings.reminders")
        appLockEnabled = defaults.bool(forKey: "settings.appLock")
    }

    var displayName: String { name.trimmingCharacters(in: .whitespaces).isEmpty ? "Your Name" : name }
    var firstName: String { name.split(separator: " ").first.map(String.init) ?? "" }

    /// Clears profile details and preferences; habits are kept.
    func resetProfile() {
        name = ""
        email = ""
        avatar = nil
        appearance = .system
        remindersEnabled = false
        appLockEnabled = false
    }
}

// MARK: - Reminders

enum ReminderScheduler {

    private static let prefix = "habit-"

    /// Replaces all scheduled habit reminders. Pass enabled = false to clear them.
    static func sync(habits: [Habit], enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)

            guard enabled else { return }
            for habit in habits {
                let content = UNMutableNotificationContent()
                content.title = habit.title
                content.body = "Time for your habit \(habit.icon)"
                content.sound = .default

                var base = DateComponents()
                base.hour = habit.startMinutes / 60
                base.minute = habit.startMinutes % 60

                let weekdays: [Int?] = habit.repeatDays.isEmpty ? [nil] : habit.repeatDays.map { Optional($0) }
                for wd in weekdays {
                    var comps = base
                    comps.weekday = wd
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let id = "\(prefix)\(habit.id.uuidString)-\(wd ?? 0)"
                    center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                }
            }
        }
    }

    /// Asks for permission if needed; calls back with whether notifications are allowed.
    static func requestPermission(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { done(granted) }
        }
    }
}

// MARK: - App lock

enum AppLock {
    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func authenticate(reason: String, _ done: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, _ in
            DispatchQueue.main.async { done(ok) }
        }
    }
}

import SwiftUI

@main
struct ProfileApp: App {
    @StateObject private var store = HabitStore()
    @StateObject private var settings = AppSettings()
    @StateObject private var auth = AuthStore()
    @State private var locked = UserDefaults.standard.bool(forKey: "settings.appLock")
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasSeenOnboarding && !auth.isLoggedIn {
                    OnboardingView { hasSeenOnboarding = true }
                } else if auth.isLoggedIn {
                    MainView()
                } else {
                    AuthView()
                }

                if auth.isLoggedIn && locked && settings.appLockEnabled {
                    LockScreen(onUnlock: unlock)
                }
            }
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(auth)
            .preferredColorScheme(settings.appearance.colorScheme)
            .onAppear {
                if locked && settings.appLockEnabled { unlock() }
                ReminderScheduler.sync(habits: store.habits, enabled: settings.remindersEnabled)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background && settings.appLockEnabled { locked = true }
                if phase == .active && locked && settings.appLockEnabled { unlock() }
            }
            .onChange(of: store.habits) { habits in
                ReminderScheduler.sync(habits: habits, enabled: settings.remindersEnabled)
            }
            .onChange(of: settings.remindersEnabled) { enabled in
                ReminderScheduler.sync(habits: store.habits, enabled: enabled)
            }
        }
    }

    private func unlock() {
        AppLock.authenticate(reason: "Unlock your habits") { ok in
            if ok { locked = false }
        }
    }
}

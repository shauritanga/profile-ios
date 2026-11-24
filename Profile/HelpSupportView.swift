import SwiftUI

struct HelpSupportView: View {

    private let faqs: [(String, String)] = [
        ("How do I add a habit?",
         "Tap the + button in the bottom bar. Pick an emoji, name the habit, set the time with the wheel and choose which days it repeats."),
        ("How do I mark a habit done or skipped?",
         "On the home screen, tap the circle next to a habit. One tap marks it completed, a second tap marks it skipped, and a third resets it."),
        ("How do I delete a habit?",
         "Open Profile, then My Habits, and long-press the habit you want to remove."),
        ("What does the Progress screen show?",
         "The chart shows the share of your scheduled habits you completed each day. Morning Routine covers habits that start before noon, Consistency is everything completed out of everything scheduled, and Discipline is how many of the habits you acted on you completed rather than skipped."),
        ("How is my streak counted?",
         "It counts the days in a row, up to today, on which you completed at least one habit."),
        ("How do reminders work?",
         "Turn on Habit reminders under Profile, then Notifications. You'll get a notification at each habit's start time on the days it repeats."),
        ("I forgot my password. What now?",
         "Your account lives only on this device, so there is no email reset. On the login screen, tap Forgot password to erase everything and start fresh."),
        ("Where is my data stored?",
         "Only on this iPhone. Your habits and history are kept in the app's storage, and your password is kept as a salted hash in the Keychain. Deleting the app removes the habits, but the Keychain entry can remain.")
    ]

    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        List {
            Section("Frequently asked questions") {
                ForEach(faqs, id: \.0) { question, answer in
                    DisclosureGroup(question) {
                        Text(answer)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(version).foregroundStyle(.secondary)
                }
                Text("Everything in this app, including your account, is stored locally on your device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

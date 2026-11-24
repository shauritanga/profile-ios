import SwiftUI

private let ink = Color(red: 0.01, green: 0.12, blue: 0.16)

private struct OnboardingPage {
    let emoji: String
    let color: Color
    let title: String
    let message: String
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        emoji: "🎯", color: Color(red: 0.98, green: 0.86, blue: 0.88),
        title: "Build better habits",
        message: "Track your daily habits in one place and make small steps part of your routine."),
    OnboardingPage(
        emoji: "⏰", color: Color(red: 1.00, green: 0.91, blue: 0.74),
        title: "Stay on track",
        message: "Get a gentle reminder when it's time for each habit, so nothing slips by."),
    OnboardingPage(
        emoji: "📈", color: Color(red: 0.84, green: 0.95, blue: 0.80),
        title: "See your progress",
        message: "Watch your streaks grow and review your statistics to stay motivated."),
    OnboardingPage(
        emoji: "🚀", color: Color(red: 0.86, green: 0.88, blue: 1.00),
        title: "Let's get started",
        message: "Create an account or sign in to start your first habit today.")
]

struct OnboardingView: View {

    @EnvironmentObject private var settings: AppSettings
    @State private var index = 0
    @State private var showDenied = false
    let onFinish: () -> Void

    private var isLast: Bool { index == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .opacity(isLast ? 0 : 1)
                    .disabled(isLast)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            TabView(selection: $index) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? ink : Color(.systemGray4))
                        .frame(width: i == index ? 24 : 8, height: 8)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: index)
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                if index == 1 && !settings.remindersEnabled {
                    Button("Enable reminders", action: enableReminders)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ink)
                }

                Button(action: next) {
                    Text(isLast ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ink, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .alert("Notifications are off", isPresented: $showDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Allow notifications for this app in Settings to get habit reminders.")
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(page.color).frame(width: 200, height: 200)
                Text(page.emoji).font(.system(size: 88))
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func next() {
        if isLast {
            onFinish()
        } else {
            withAnimation { index += 1 }
        }
    }

    private func enableReminders() {
        ReminderScheduler.requestPermission { granted in
            if granted {
                settings.remindersEnabled = true
                withAnimation { index += 1 }
            } else {
                settings.remindersEnabled = false
                showDenied = true
            }
        }
    }
}

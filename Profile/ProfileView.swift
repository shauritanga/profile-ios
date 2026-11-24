import SwiftUI

struct ProfileView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: HabitStore
    @EnvironmentObject private var auth: AuthStore
    @State private var confirmLogout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Top Title
                    HStack {
                        Text("Profile")
                            .font(.system(size: 32, weight: .bold))

                        Spacer()

                        HStack(spacing: 6) {
                            Text("\(store.streak)")
                                .font(.headline)

                            Text("🔥")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.card)
                        .clipShape(Capsule())
                    }

                    // MARK: - Profile Information
                    VStack(spacing: 12) {

                        AvatarView(size: 110)

                        Text(settings.displayName)
                            .font(.system(size: 26, weight: .semibold))

                        Text(settings.email.isEmpty ? "Add your email" : settings.email)
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)

                    // MARK: - Settings Card
                    VStack(spacing: 0) {
                        
                        

                        NavigationLink {
                            MyHabitsView()
                        } label: {
                            ProfileMenuRow(
                                icon: "checklist",
                                title: "My Habits"
                            )
                        }
                        .buttonStyle(.plain)
                        Divider()
                            .padding(.leading, 60)

                        NavigationLink {
                            PersonalInfoView()
                        } label: {
                            ProfileMenuRow(
                                icon: "person",
                                title: "Personal Info"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 60)

                        NavigationLink {
                            SecurityView()
                        } label: {
                            ProfileMenuRow(
                                icon: "lock",
                                title: "Password & Security"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 60)

                        Group {
                        NavigationLink {
                            NotificationsView()
                        } label: {
                            ProfileMenuRow(
                                icon: "bell",
                                title: "Notifications"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 60)

                        NavigationLink {
                            AppearanceView()
                        } label: {
                            ProfileMenuRow(
                                icon: "display",
                                title: "Appearance"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 60)

                        NavigationLink {
                            HelpSupportView()
                        } label: {
                            ProfileMenuRow(
                                icon: "questionmark.circle",
                                title: "Help & Support"
                            )
                        }
                        .buttonStyle(.plain)
                        }
                    }
                    .background(Color.card)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24)
                    )

                    // MARK: - Logout
                    Button {
                        confirmLogout = true
                    } label: {
                        HStack(spacing: 14) {

                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 24))

                            Text("Log Out")
                                .font(.system(size: 19, weight: .medium))

                            Spacer()
                        }
                        .foregroundStyle(.red)
                        .padding(22)
                        .background(Color.card)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 22)
                        )
                    }

                    Text(appVersion)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog(
                "Log out?",
                isPresented: $confirmLogout,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) { logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your habits stay on this device. Log back in with your password.")
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    private func logout() {
        auth.logOut()
    }
}

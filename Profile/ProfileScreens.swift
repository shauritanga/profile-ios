import SwiftUI
import PhotosUI

// MARK: - Avatar

struct AvatarView: View {
    @EnvironmentObject private var settings: AppSettings
    var size: CGFloat = 110

    var body: some View {
        Group {
            if let image = settings.avatar {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("me").resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.card, lineWidth: 4))
    }
}

// MARK: - Personal info

struct PersonalInfoView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var name = ""
    @State private var email = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        AvatarView(size: 100)

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Text("Change photo")
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Name") {
                TextField("Your name", text: $name)
                    .textContentType(.name)
            }

            Section {
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Email")
            } footer: {
                if let error {
                    Text(error).foregroundStyle(.red)
                } else {
                    Text("This is also the email you log in with.")
                }
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: save).fontWeight(.semibold)
            }
        }
        .onAppear {
            name = settings.name
            email = auth.email.isEmpty ? settings.email : auth.email
        }
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let resized = image.scaled(toMax: 600)
                    await MainActor.run { settings.avatar = resized }
                }
            }
        }
    }

    private func save() {
        do {
            try auth.updateEmail(email)
            settings.name = name.trimmingCharacters(in: .whitespaces)
            settings.email = auth.email
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private extension UIImage {
    func scaled(toMax side: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > side else { return self }
        let scale = side / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Notifications

struct NotificationsView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: HabitStore
    @State private var showDenied = false

    var body: some View {
        Form {
            Section {
                Toggle("Habit reminders", isOn: Binding(
                    get: { settings.remindersEnabled },
                    set: { setReminders($0) }
                ))
            } footer: {
                Text("You get a notification at each habit's start time, on the days it repeats.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications are off", isPresented: $showDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow notifications for this app in Settings to get habit reminders.")
        }
    }

    private func setReminders(_ on: Bool) {
        guard on else {
            settings.remindersEnabled = false
            return
        }
        ReminderScheduler.requestPermission { granted in
            if granted {
                settings.remindersEnabled = true
            } else {
                settings.remindersEnabled = false
                showDenied = true
            }
        }
    }
}

// MARK: - Appearance

struct AppearanceView: View {

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section {
                ForEach(Appearance.allCases) { option in
                    Button {
                        settings.appearance = option
                    } label: {
                        HStack {
                            Text(option.title).foregroundStyle(.primary)
                            Spacer()
                            if settings.appearance == option {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } footer: {
                Text("System follows your iPhone's light or dark setting.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Security

struct SecurityView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var store: HabitStore
    @State private var showUnavailable = false
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section {
                NavigationLink("Change password") { ChangePasswordView() }
            }

            Section {
                Toggle("Lock app", isOn: Binding(
                    get: { settings.appLockEnabled },
                    set: { setLock($0) }
                ))
            } footer: {
                Text("Ask for Face ID, Touch ID or your device passcode whenever the app is opened.")
            }

            Section {
                Button("Delete account", role: .destructive) { confirmDelete = true }
            } footer: {
                Text("Removes your account and all data from this device.")
            }
        }
        .navigationTitle("Password & Security")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account and all data", role: .destructive) {
                store.eraseAll()
                settings.resetProfile()
                auth.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account, habits and history from this device.")
        }
        .alert("Can't turn on lock", isPresented: $showUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set a passcode on this device first, then try again.")
        }
    }

    private func setLock(_ on: Bool) {
        guard on else {
            AppLock.authenticate(reason: "Turn off app lock") { ok in
                if ok { settings.appLockEnabled = false }
            }
            return
        }
        guard AppLock.isAvailable else {
            showUnavailable = true
            return
        }
        AppLock.authenticate(reason: "Turn on app lock") { ok in
            if ok { settings.appLockEnabled = true }
        }
    }
}

// MARK: - Lock screen

struct LockScreen: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))

                Text("Locked")
                    .font(.system(size: 24, weight: .bold))

                Button("Unlock", action: onUnlock)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

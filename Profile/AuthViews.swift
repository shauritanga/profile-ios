import SwiftUI

private let ink = Color(red: 0.01, green: 0.12, blue: 0.16)

private struct AuthField: View {
    let placeholder: String
    @Binding var text: String
    var secure = false
    var keyboard: UIKeyboardType = .default
    var content: UITextContentType?

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                    .autocorrectionDisabled()
            }
        }
        .textContentType(content)
        .font(.system(size: 17))
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Sign up when this device has no account yet, otherwise log in.
struct AuthView: View {

    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: HabitStore

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var error: String?
    @State private var confirmReset = false

    private var signingUp: Bool { !auth.hasAccount }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(signingUp ? "Create your account" : "Welcome back")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.top, 50)

                    Text(signingUp
                         ? "Your account and habits stay on this device. Nothing is sent anywhere."
                         : "Log in to see your habits.")
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 14)

                    if signingUp {
                        AuthField(placeholder: "Name", text: $name, content: .name)
                    }

                    AuthField(placeholder: "Email", text: $email, keyboard: .emailAddress, content: .username)
                    AuthField(placeholder: "Password", text: $password, secure: true,
                              content: signingUp ? .newPassword : .password)

                    if signingUp {
                        AuthField(placeholder: "Confirm password", text: $confirm, secure: true, content: .newPassword)

                        Text("At least 8 characters.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: submit) {
                        Text(signingUp ? "Sign Up" : "Log In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(ink)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, 8)

                    if !signingUp {
                        Button("Forgot password?") { confirmReset = true }
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear { if !signingUp && email.isEmpty { email = auth.email } }
        .confirmationDialog(
            "Reset this device?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Erase everything and start over", role: .destructive) { eraseAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account is stored only on this device, so it can't be recovered by email. Resetting deletes the account, all habits and your history.")
        }
    }

    private func submit() {
        error = nil
        do {
            if signingUp {
                try auth.signUp(name: name, email: email, password: password, confirm: confirm)
                settings.name = name.trimmingCharacters(in: .whitespaces)
                settings.email = auth.email
            } else {
                try auth.logIn(email: email, password: password)
            }
            password = ""
            confirm = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func eraseAll() {
        auth.deleteAccount()
        store.eraseAll()
        settings.resetProfile()
        password = ""
        error = nil
    }
}

struct ChangePasswordView: View {

    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                SecureField("Current password", text: $current)
            }
            Section {
                SecureField("New password", text: $new)
                SecureField("Confirm new password", text: $confirm)
            } footer: {
                if let error {
                    Text(error).foregroundStyle(.red)
                } else {
                    Text("At least 8 characters.")
                }
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    do {
                        try auth.changePassword(current: current, new: new, confirm: confirm)
                        dismiss()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
                .fontWeight(.semibold)
                .disabled(current.isEmpty || new.isEmpty)
            }
        }
    }
}

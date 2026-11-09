import SwiftUI

/// Login / Sign Up screen.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel

    enum Mode: String, CaseIterable, Identifiable {
        case login = "Log In"
        case signUp = "Sign Up"
        var id: String { rawValue }
    }

    // @State = local data owned by this view
    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 40)
                    .accessibilityHidden(true)
                Text("GymLog").font(.largeTitle.bold())
                Text("Personal workout & exercise tracker")
                    .foregroundStyle(.secondary)

                // Picker: switch between the two modes
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password (6+ characters)", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: submit) {
                    HStack {
                        if auth.isLoading { ProgressView() }
                        Text(mode.rawValue).bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(auth.isLoading)
                .accessibilityLabel(mode == .login ? "Log in" : "Create account")
            }
            .padding()
        }
        .errorAlert(message: $auth.errorMessage)
    }

    private func submit() {
        Task {
            if mode == .login {
                await auth.signIn(email: email, password: password)
            } else {
                await auth.register(email: email, password: password)
            }
        }
    }
}

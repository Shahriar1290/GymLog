import Foundation
import FirebaseAuth

/// Handles register / login / logout with Firebase Authentication.
/// ObservableObject + @Published = the UI redraws automatically when these values change.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var userId: String?          // nil = signed out
    @Published var userEmail: String?
    @Published var isCheckingAuth = true    // true until Firebase reports the first auth state
    @Published var isLoading = false        // true while a request is running
    @Published var errorMessage: String?    // shown in an alert

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    /// Keeps the user signed in across launches: Firebase restores the saved session and
    /// calls this listener right away, then again on every login/logout.
    func startListening() {
        guard listenerHandle == nil else { return }
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let uid = user?.uid
            let email = user?.email
            Task { @MainActor in
                self?.userId = uid
                self?.userEmail = email
                self?.isCheckingAuth = false
            }
        }
    }

    func signIn(email: String, password: String) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let problem = validate(email: cleanEmail, password: password) {
            errorMessage = problem
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await Auth.auth().signIn(withEmail: cleanEmail, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func register(email: String, password: String) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let problem = validate(email: cleanEmail, password: password) {
            errorMessage = problem
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Validation

    /// Returns an error message, or nil when the input is valid.
    private func validate(email: String, password: String) -> String? {
        if email.isEmpty || password.isEmpty { return "Please enter your email and password." }
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        if email.range(of: pattern, options: .regularExpression) == nil {
            return "Please enter a valid email address."
        }
        if password.count < 6 { return "Password must be at least 6 characters." }
        return nil
    }

    /// Turns Firebase error codes into messages a normal person can read.
    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == "FIRAuthErrorDomain",
              let code = AuthErrorCode.Code(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .emailAlreadyInUse: return "An account with this email already exists."
        case .invalidEmail: return "That email address is not valid."
        case .wrongPassword, .invalidCredential, .userNotFound: return "Incorrect email or password."
        case .weakPassword: return "That password is too weak. Use at least 6 characters."
        case .networkError: return "Network error. Check your internet connection."
        case .tooManyRequests: return "Too many attempts. Please try again later."
        default: return error.localizedDescription
        }
    }
}

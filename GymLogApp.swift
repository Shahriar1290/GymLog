import SwiftUI
import FirebaseCore
import UserNotifications

// MARK: - AppDelegate
// SwiftUI has no built-in "app launched" hook for Firebase, so we attach a classic
// UIApplicationDelegate with @UIApplicationDelegateAdaptor.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Reads GoogleService-Info.plist and connects the app to your Firebase project.
        FirebaseApp.configure()
        // DELEGATE PATTERN: tell the notification center that NotificationManager is its delegate.
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        return true
    }
}

// MARK: - App entry point
@main
struct GymLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // @StateObject: the App owns ONE AuthViewModel for its whole lifetime.
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)      // makes `auth` available to every child view
                .tint(AppTheme.accent)        // app-wide accent colour
        }
    }
}

// MARK: - Root view: switches between login and the main app
struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isCheckingAuth {
                ProgressView("Loading…")          // waiting for Firebase to tell us if a user is signed in
            } else if auth.userId != nil {
                MainTabView()                     // signed in
            } else {
                AuthView()                        // signed out
            }
        }
        // Start listening for sign-in/sign-out changes once the UI exists
        // (this is after FirebaseApp.configure() has run).
        .onAppear { auth.startListening() }
    }
}

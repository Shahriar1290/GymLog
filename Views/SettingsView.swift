import SwiftUI

/// Profile + reminder settings + log out.
struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    // @ObservedObject: this view does NOT own the object, it only watches the shared instance.
    @ObservedObject private var notifications = NotificationManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Email", value: auth.userEmail ?? "—")
                }

                Section {
                    Toggle("Daily workout reminder", isOn: Binding(
                        get: { notifications.isEnabled },
                        set: { notifications.setReminder(enabled: $0) }
                    ))
                    DatePicker("Reminder time",
                               selection: $notifications.reminderTime,
                               displayedComponents: .hourAndMinute)
                        .disabled(!notifications.isEnabled)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("A local notification repeats every day at the chosen time.")
                }

                Section {
                    Button(role: .destructive) {
                        auth.signOut()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Log out")
                }
            }
            .navigationTitle("Settings")
            .errorAlert(message: $notifications.errorMessage)
        }
        .errorAlert(message: $auth.errorMessage)
    }
}

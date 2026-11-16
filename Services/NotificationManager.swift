import Foundation
import UserNotifications

/// Schedules the daily workout reminder.
/// DELEGATE PATTERN: this class conforms to UNUserNotificationCenterDelegate, so the system
/// notification center can "call us back" (for example in willPresent below).
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()   // one shared instance for the whole app

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: Keys.time)
            if isEnabled { scheduleDailyReminder() }    // re-schedule when the time changes
        }
    }
    @Published var errorMessage: String?

    private enum Keys {
        static let enabled = "reminderEnabled"
        static let time = "reminderTime"
    }
    private let center = UNUserNotificationCenter.current()
    private let requestId = "gymlog.daily.reminder"

    private override init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: Keys.enabled)
        if let saved = defaults.object(forKey: Keys.time) as? Date {
            reminderTime = saved
        } else {
            // default reminder time: 18:00
            reminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        }
        super.init()
    }

    // MARK: - Public API used by SettingsView

    /// Called when the user flips the Toggle.
    func setReminder(enabled: Bool) {
        if enabled {
            requestPermission { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.isEnabled = true
                    self.scheduleDailyReminder()
                } else {
                    self.isEnabled = false
                    self.errorMessage = "Notifications are turned off. Enable them in Settings › Notifications › GymLog."
                }
            }
        } else {
            isEnabled = false
            cancelReminder()
        }
    }

    // MARK: - Permission and scheduling

    private func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [requestId])

        let content = UNMutableNotificationContent()
        content.title = "Time to train 💪"
        content.body = "Don't forget to log today's workout in GymLog."
        content.sound = .default

        // Only hour + minute are given, so the trigger fires every day at that time.
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            if let error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
            }
        }
    }

    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification arrives while the app is open (foreground).
    /// Without this method iOS would silently hide the notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

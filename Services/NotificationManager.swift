import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private enum ReminderSchedule {
        static let morning = "mindharbor.reminder.morning"
        static let afternoon = "mindharbor.reminder.afternoon"
        static let evening = "mindharbor.reminder.evening"
        static let custom = "mindharbor.reminder.custom"
    }

    private var hasRequestedAuthorization = false
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded(completion: (@escaping (Bool) -> Void)? = nil) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            let allowed = settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional ||
            settings.authorizationStatus == .ephemeral

            if allowed {
                completion?(true)
                return
            }

            if self.hasRequestedAuthorization {
                completion?(false)
                return
            }

            self.hasRequestedAuthorization = true
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                completion?(granted)
            }
        }
    }

    func configureReminders(
        morning: Bool,
        afternoon: Bool,
        evening: Bool,
        customEnabled: Bool,
        customHour: Int,
        customMinute: Int
    ) {
        requestAuthorizationIfNeeded { [weak self] allowed in
            guard allowed else { return }
            guard let self else { return }

            self.center.removeAllPendingNotificationRequests()
            guard morning || afternoon || evening || customEnabled else { return }

            let bodyTone = UserDefaults.standard.bool(forKey: MindHarborKeys.privateNotifications)
                ? "MindHarbor reminder"
                : "MindHarbor reminder"

            if morning {
                self.scheduleReminder(
                    identifier: ReminderSchedule.morning,
                    title: bodyTone,
                    body: "Would you like a moment to check in?",
                    hour: 9,
                    minute: 0
                )
            }

            if afternoon {
                self.scheduleReminder(
                    identifier: ReminderSchedule.afternoon,
                    title: bodyTone,
                    body: "Your journal is here if you'd like it.",
                    hour: 14,
                    minute: 30
                )
            }

            if evening {
                self.scheduleReminder(
                    identifier: ReminderSchedule.evening,
                    title: bodyTone,
                    body: "How has today been for you?",
                    hour: 20,
                    minute: 0
                )
            }

            if customEnabled {
                let normalizedHour = max(0, min(23, customHour))
                let normalizedMinute = max(0, min(59, customMinute))
                self.scheduleReminder(
                    identifier: ReminderSchedule.custom,
                    title: bodyTone,
                    body: "Your journal is here if you'd like it.",
                    hour: normalizedHour,
                    minute: normalizedMinute
                )
            }
        }
    }

    private func scheduleReminder(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.interruptionLevel = .passive
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("MindHarbor reminder error: \(error.localizedDescription)") }
        }
    }
}

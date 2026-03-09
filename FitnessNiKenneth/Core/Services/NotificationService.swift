import Foundation
import UserNotifications
import UIKit

// MARK: - NotificationService

struct NotificationService {

    static let restTimerID = "rest-timer"

    // MARK: - Permission

    static func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.sound, .alert, .badge])
    }

    // MARK: - Rest Timer Notification

    static func scheduleRestEnd(after seconds: Int) {
        guard seconds > 0 else { return }

        // Cancel any existing rest notification before scheduling a new one
        cancelRestEnd()

        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to get back to it."
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: restTimerID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func cancelRestEnd() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [restTimerID])
    }

    // MARK: - Haptic

    static func hapticRestComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func hapticSetComplete() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - AppNotificationDelegate

/// Suppresses the rest-timer banner when the app is in the foreground
/// (the in-app rest timer UI is already visible).
/// All other notifications show normally.
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == NotificationService.restTimerID {
            // In-app UI handles this — suppress the banner, but keep sound
            completionHandler([.sound])
        } else {
            completionHandler([.banner, .sound])
        }
    }
}

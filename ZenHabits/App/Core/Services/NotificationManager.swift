//
//  NotificationManager.swift
//  HabitTracker
//
//  Handles local notification scheduling for habit reminders
//  Pure Engineering: No tracking, no analytics - just helpful reminders
//

import Foundation
import UserNotifications

// MARK: - NotificationManager
/// Singleton manager for scheduling and canceling habit reminder notifications
@MainActor
final class NotificationManager: NSObject {
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Current authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Init
    private override init() {
        super.init()
        // Check current status on init
        Task {
            await refreshAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Requests notification authorization from the user
    /// - Returns: True if authorized, false otherwise
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await refreshAuthorizationStatus()
            return granted
        } catch {
            print("NotificationManager: Authorization error - \(error.localizedDescription)")
            return false
        }
    }
    
    /// Refreshes the current authorization status
    func refreshAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    /// Checks if notifications are currently authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    /// Checks if we can request authorization (not denied)
    var canRequestAuthorization: Bool {
        authorizationStatus == .notDetermined
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedules a daily notification for a habit at its reminder time
    /// - Parameter habit: The habit to schedule notification for
    func scheduleNotification(for habit: Habit) async {
        // Ensure we have authorization
        guard isAuthorized else {
            print("NotificationManager: Not authorized to schedule notifications")
            return
        }
        
        // Ensure habit has a reminder time
        guard let reminderTime = habit.reminderTime else {
            print("NotificationManager: Habit has no reminder time set")
            return
        }
        
        // Cancel any existing notification for this habit first
        await cancelNotification(for: habit)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time for \(habit.title)"
        content.body = habit.isCritical 
            ? "Don't forget your essential habit! \(habit.emoji)"
            : "Keep your streak going! \(habit.emoji)"
        content.sound = .default
        content.badge = 1
        
        // Add habit ID to userInfo for handling
        content.userInfo = ["habitId": habit.id.uuidString]
        
        // Create trigger - daily at the specified time
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: reminderTime)
        dateComponents.minute = calendar.component(.minute, from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request with habit ID as identifier
        let identifier = notificationIdentifier(for: habit)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Scheduled notification for '\(habit.title)' at \(habit.formattedReminderTime ?? "unknown")")
        } catch {
            print("NotificationManager: Failed to schedule notification - \(error.localizedDescription)")
        }
    }
    
    /// Cancels any scheduled notification for a habit
    /// - Parameter habit: The habit to cancel notification for
    func cancelNotification(for habit: Habit) async {
        let identifier = notificationIdentifier(for: habit)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("NotificationManager: Cancelled notification for '\(habit.title)'")
    }
    
    /// Cancels all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("NotificationManager: Cancelled all notifications")
    }
    
    // MARK: - Helpers
    
    /// Generates a unique notification identifier for a habit
    private func notificationIdentifier(for habit: Habit) -> String {
        "habit-reminder-\(habit.id.uuidString)"
    }
    
    /// Returns all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    /// Clears the app badge
    func clearBadge() async {
        do {
            try await notificationCenter.setBadgeCount(0)
        } catch {
            print("NotificationManager: Failed to clear badge - \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Handling
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is delivered while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner and play sound even when app is open
        return [.banner, .sound, .badge]
    }
    
    /// Called when user taps on a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        if let habitIdString = userInfo["habitId"] as? String {
            print("NotificationManager: User tapped notification for habit: \(habitIdString)")
            // Future: Could post notification to navigate to habit detail
        }
    }
}


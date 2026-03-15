//
//  AddHabitViewModel.swift
//  HabitTracker
//
//  MVVM: Manages form state and validation for habit creation AND editing
//  Pure Engineering: No upsells, no premium features
//

import Foundation
import SwiftUI

// MARK: - Weekday
// CaseIterable allows iteration in UI
// Identifiable required for ForEach
enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    /// Short display name (Mon, Tue, etc.)
    var shortName: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }
    
    /// Single letter for compact display
    var letter: String {
        switch self {
        case .sunday: "S"
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "T"
        case .friday: "F"
        case .saturday: "S"
        }
    }
    
    /// Returns weekdays in locale-appropriate order (Mon-Sun or Sun-Sat)
    static var orderedCases: [Weekday] {
        // Start week on Monday (common in most locales)
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
}

// MARK: - Preset Colors
// Curated palette that works well in both light and dark modes
struct HabitColor: Identifiable {
    let id = UUID()
    let name: String
    let hex: String
    
    var color: Color {
        Color(hex: hex)
    }
    
    static let presets: [HabitColor] = [
        HabitColor(name: "Indigo", hex: "5E5CE6"),
        HabitColor(name: "Blue", hex: "007AFF"),
        HabitColor(name: "Cyan", hex: "32ADE6"),
        HabitColor(name: "Teal", hex: "30B0C7"),
        HabitColor(name: "Green", hex: "34C759"),
        HabitColor(name: "Mint", hex: "00C7BE"),
        HabitColor(name: "Yellow", hex: "FFCC00"),
        HabitColor(name: "Orange", hex: "FF9500"),
        HabitColor(name: "Red", hex: "FF3B30"),
        HabitColor(name: "Pink", hex: "FF2D55"),
        HabitColor(name: "Purple", hex: "AF52DE"),
        HabitColor(name: "Brown", hex: "A2845E"),
    ]
}

// MARK: - Preset Emojis
struct HabitEmoji {
    static let presets: [String] = [
        "🧘", "📚", "💧", "🏃", "🎯",
        "✍️", "🌱", "💪", "🧠", "❤️",
        "🎨", "🎵", "💤", "🍎", "☀️",
        "🧹", "💊", "🚶", "🧘‍♀️", "📝"
    ]
}

// MARK: - AddHabitViewModel
@Observable
@MainActor
final class AddHabitViewModel {
    
    // MARK: - Mode
    /// Determines if we're creating a new habit or editing an existing one
    enum Mode {
        case add
        case edit(Habit)
        
        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }
        
        var navigationTitle: String {
            switch self {
            case .add: "New Habit"
            case .edit: "Edit Habit"
            }
        }
        
        var saveButtonTitle: String {
            switch self {
            case .add: "Save"
            case .edit: "Update"
            }
        }
    }
    
    // MARK: - Properties
    let mode: Mode
    
    // MARK: - Form State
    var title: String = ""
    var selectedEmoji: String = HabitEmoji.presets[0]
    var selectedColorHex: String = HabitColor.presets[0].hex
    var selectedDays: Set<Weekday> = Set(Weekday.allCases) // Default: every day
    
    // MARK: - Priority & Reminders
    var isCritical: Bool = false
    var hasReminder: Bool = false
    var reminderTime: Date = defaultReminderTime
    
    /// Default reminder time: 9:00 AM
    private static var defaultReminderTime: Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // MARK: - UI State
    var isSaving = false
    var errorMessage: String?
    var didSaveSuccessfully = false
    var showingNotificationDeniedAlert = false
    
    // MARK: - Dependencies
    private let habitService: HabitServiceProtocol
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Init
    /// Creates a ViewModel for adding or editing a habit
    /// - Parameters:
    ///   - habitService: Service for persistence operations
    ///   - habitToEdit: If provided, switches to edit mode and pre-fills form
    init(habitService: HabitServiceProtocol, habitToEdit: Habit? = nil) {
        self.habitService = habitService
        
        if let habit = habitToEdit {
            // Edit mode: Pre-fill form with existing habit data
            self.mode = .edit(habit)
            self.title = habit.title
            self.selectedEmoji = habit.emoji
            self.selectedColorHex = habit.colorHex
            self.isCritical = habit.isCritical
            self.hasReminder = habit.reminderTime != nil
            self.reminderTime = habit.reminderTime ?? Self.defaultReminderTime
            
            // Convert frequency to selected days
            switch habit.frequency {
            case .daily:
                self.selectedDays = Set(Weekday.allCases)
            case .weekly(let days):
                self.selectedDays = Set(days.compactMap { Weekday(rawValue: $0) })
            case .custom(_):
                // For custom intervals, default to daily in the UI
                // (Custom intervals are an edge case)
                self.selectedDays = Set(Weekday.allCases)
            }
        } else {
            // Add mode: Use defaults
            self.mode = .add
        }
    }
    
    // MARK: - Validation
    // Computed property: Reactively updates UI when dependencies change
    var isValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        return !trimmedTitle.isEmpty && !selectedDays.isEmpty
    }
    
    /// Detailed validation errors for user feedback
    var validationErrors: [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Please enter a habit name")
        }
        
        if selectedDays.isEmpty {
            errors.append("Select at least one day")
        }
        
        return errors
    }
    
    // MARK: - Notification Status
    
    /// Whether notifications are authorized
    var notificationsAuthorized: Bool {
        notificationManager.isAuthorized
    }
    
    /// Whether we can request notification permissions
    var canRequestNotifications: Bool {
        notificationManager.canRequestAuthorization
    }
    
    // MARK: - Actions
    
    /// Toggles a weekday's selection state
    func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            // Don't allow deselecting the last day
            guard selectedDays.count > 1 else { return }
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    /// Checks if a specific day is selected
    func isDaySelected(_ day: Weekday) -> Bool {
        selectedDays.contains(day)
    }
    
    /// Quick select: Every day
    func selectAllDays() {
        selectedDays = Set(Weekday.allCases)
    }
    
    /// Quick select: Weekdays only
    func selectWeekdays() {
        selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
    }
    
    /// Quick select: Weekends only
    func selectWeekends() {
        selectedDays = [.saturday, .sunday]
    }
    
    /// Called when user toggles reminder on
    func onReminderToggled() async {
        if hasReminder {
            // User is enabling reminders - check/request permissions
            if !notificationManager.isAuthorized {
                if notificationManager.canRequestAuthorization {
                    // Request permission
                    let granted = await notificationManager.requestAuthorization()
                    if !granted {
                        hasReminder = false
                        showingNotificationDeniedAlert = true
                    }
                } else {
                    // Previously denied - show alert to go to settings
                    hasReminder = false
                    showingNotificationDeniedAlert = true
                }
            }
        }
    }
    
    /// Creates or updates the habit based on mode
    func saveHabit() async {
        guard isValid else { return }
        
        isSaving = true
        errorMessage = nil
        
        // Build frequency from selected days
        let frequency: Frequency
        if selectedDays.count == 7 {
            frequency = .daily
        } else {
            let dayNumbers = selectedDays.map { $0.rawValue }
            frequency = .weekly(days: Set(dayNumbers))
        }
        
        // Determine reminder time
        let finalReminderTime: Date? = hasReminder ? reminderTime : nil
        
        do {
            switch mode {
            case .add:
                // Create new habit
                let habit = Habit(
                    title: title.trimmingCharacters(in: .whitespaces),
                    emoji: selectedEmoji,
                    colorHex: selectedColorHex,
                    frequency: frequency,
                    isCritical: isCritical,
                    reminderTime: finalReminderTime
                )
                try await habitService.addHabit(habit)
                
                // Schedule notification if reminder is set
                if hasReminder {
                    await notificationManager.scheduleNotification(for: habit)
                }
                
            case .edit(let existingHabit):
                // Cancel existing notification first
                await notificationManager.cancelNotification(for: existingHabit)
                
                // Update existing habit
                existingHabit.title = title.trimmingCharacters(in: .whitespaces)
                existingHabit.emoji = selectedEmoji
                existingHabit.colorHex = selectedColorHex
                existingHabit.frequency = frequency
                existingHabit.isCritical = isCritical
                existingHabit.reminderTime = finalReminderTime
                try await habitService.updateHabit(existingHabit)
                
                // Schedule new notification if reminder is set
                if hasReminder {
                    await notificationManager.scheduleNotification(for: existingHabit)
                }
            }
            
            didSaveSuccessfully = true
        } catch {
            errorMessage = "Could not save habit. Please try again."
        }
        
        isSaving = false
    }
    
    /// Resets form to initial state
    func reset() {
        title = ""
        selectedEmoji = HabitEmoji.presets[0]
        selectedColorHex = HabitColor.presets[0].hex
        selectedDays = Set(Weekday.allCases)
        isCritical = false
        hasReminder = false
        reminderTime = Self.defaultReminderTime
        isSaving = false
        errorMessage = nil
        didSaveSuccessfully = false
    }
}


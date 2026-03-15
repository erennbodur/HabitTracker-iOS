//
//  Habit.swift
//  ZenHabits
//
//  Core domain model for habit tracking.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Habit Model
/// Primary entity representing a trackable habit.
///
/// Design Decisions:
/// - `@Model`: SwiftData macro for automatic persistence
/// - `colorHex` stored as String because SwiftData cannot persist SwiftUI Color
/// - `frequencyData` stores Frequency as encoded Data for SwiftData compatibility
/// - `archivedAt` enables soft-delete pattern, preserving historical data
/// - `isCritical` marks essential habits that appear in a separate section
/// - `reminderTime` stores optional daily reminder time for notifications
/// - One-to-many relationship with Completion via `@Relationship`
@Model
final class Habit {
    
    // MARK: - Properties
    
    /// Unique identifier - explicit for clearer code, though SwiftData auto-generates
    var id: UUID
    
    /// User-facing name of the habit (e.g., "Drink Water", "Meditate")
    var title: String
    
    /// Visual identifier - SF Symbol name or emoji character
    var emoji: String
    
    /// Color stored as hex string (e.g., "FF5733")
    /// Convert to SwiftUI Color via Color+Extensions
    var colorHex: String
    
    /// Frequency stored as encoded JSON Data for SwiftData compatibility
    /// Access via `frequency` computed property
    var frequencyData: Data
    
    /// Timestamp when habit was created - used for sorting and analytics
    var createdAt: Date
    
    /// Soft-delete timestamp. When set, habit is "archived" not deleted.
    /// This preserves historical completion data for statistics.
    var archivedAt: Date?
    
    /// Marks the habit as "Essential" - displayed in a priority section
    /// Default false for backward compatibility with existing data
    var isCritical: Bool = false
    
    /// Optional daily reminder time. When set, schedules local notifications.
    /// Stored as Date but only hour/minute components are used.
    /// Default nil for backward compatibility with existing data
    var reminderTime: Date? = nil
    
    // MARK: - Relationships
    
    /// All completions for this habit.
    /// `cascade`: When habit is deleted, completions are also deleted.
    /// `inverse`: SwiftData automatically manages the back-reference.
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion] = []
    
    // MARK: - Computed Properties
    
    /// How often the habit should be completed
    /// Decoded from `frequencyData` storage
    var frequency: Frequency {
        get {
            Frequency.decode(from: frequencyData)
        }
        set {
            frequencyData = newValue.encodedData
        }
    }
    
    /// Whether the habit is currently active (not archived)
    var isActive: Bool {
        archivedAt == nil
    }
    
    /// SwiftUI Color computed from hex string
    var color: Color {
        Color(hex: colorHex)
    }
    
    /// Whether the habit has a reminder set
    var hasReminder: Bool {
        reminderTime != nil
    }
    
    /// Formatted reminder time string (e.g., "9:00 AM")
    var formattedReminderTime: String? {
        guard let reminderTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminderTime)
    }
    
    // MARK: - Initialization
    
    /// Creates a new Habit with sensible defaults.
    ///
    /// - Parameters:
    ///   - title: Display name for the habit
    ///   - emoji: SF Symbol name or emoji (default: "star.fill")
    ///   - colorHex: Hex color string (default: Indigo)
    ///   - frequency: Completion frequency (default: .daily)
    ///   - isCritical: Whether this is an essential habit (default: false)
    ///   - reminderTime: Optional daily reminder time (default: nil)
    init(
        id: UUID = UUID(),
        title: String,
        emoji: String = "star.fill",
        colorHex: String = "5856D6",
        frequency: Frequency = .daily,
        createdAt: Date = .now,
        isCritical: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.colorHex = colorHex
        self.frequencyData = frequency.encodedData
        self.createdAt = createdAt
        self.archivedAt = nil
        self.isCritical = isCritical
        self.reminderTime = reminderTime
    }
}

// Note: @Model automatically synthesizes Equatable, Hashable, and Identifiable
// Do NOT add manual implementations - they will conflict with SwiftData

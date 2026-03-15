//
//  Completion.swift
//  ZenHabits
//
//  Represents a single completion record for a habit.
//

import Foundation
import SwiftData

// MARK: - Completion Model
/// Records when a habit was completed.
///
/// Design Decisions:
/// - Separate entity (not embedded in Habit) for efficient queries
///   e.g., "Get all completions this week across all habits"
/// - `date` is normalized to start-of-day for consistent streak calculation
/// - Back-reference to Habit enables bidirectional navigation
@Model
final class Completion {
    
    // MARK: - Properties
    
    /// Unique identifier for this completion record
    var id: UUID
    
    /// The date when the habit was completed.
    /// Normalized to 00:00:00 of the day for consistent comparison.
    var date: Date
    
    /// Optional note for this completion (future feature: journaling)
    var note: String?
    
    // MARK: - Relationships
    
    /// The habit this completion belongs to.
    /// SwiftData manages this inverse relationship automatically.
    var habit: Habit?
    
    // MARK: - Initialization
    
    /// Creates a new Completion record.
    ///
    /// - Parameters:
    ///   - date: When the habit was completed (auto-normalized to start of day)
    ///   - habit: The parent habit
    ///   - note: Optional note about this completion
    init(
        id: UUID = UUID(),
        date: Date = .now,
        habit: Habit? = nil,
        note: String? = nil
    ) {
        self.id = id
        // Normalize to start of day for consistent streak calculations
        self.date = Calendar.current.startOfDay(for: date)
        self.habit = habit
        self.note = note
    }
}

// MARK: - Completion + Comparable
/// Allows sorting completions by date
extension Completion: Comparable {
    static func < (lhs: Completion, rhs: Completion) -> Bool {
        lhs.date < rhs.date
    }
}

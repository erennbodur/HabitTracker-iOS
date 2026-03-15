//
//  HabitService.swift
//  ZenHabits
//
//  Pure Engineering: SwiftData CRUD operations for Habits
//  Architecture: Service layer isolates data operations from ViewModels
//

import Foundation
import SwiftData

// MARK: - Protocol
// Protocol-based design enables dependency injection and testability
// ViewModels depend on this protocol, not the concrete implementation
protocol HabitServiceProtocol: Sendable {
    func fetchAllHabits() async throws -> [Habit]
    func fetchActiveHabits() async throws -> [Habit]
    func addHabit(_ habit: Habit) async throws
    func updateHabit(_ habit: Habit) async throws
    func archiveHabit(_ habit: Habit) async throws
    func deleteHabit(_ habit: Habit) async throws
    func toggleCompletion(for habit: Habit, on date: Date) async throws
    func calculateCurrentStreak(for habit: Habit) async -> Int
    func calculateLongestStreak(for habit: Habit) async -> Int
}

// MARK: - HabitService
// @MainActor: Ensures all SwiftData operations run on main thread
// This is required because ModelContext is not Sendable
@MainActor
final class HabitService: HabitServiceProtocol {
    
    // MARK: - Dependencies
    // ModelContext injected via initializer for testability
    private let modelContext: ModelContext
    
    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Fetches all habits including archived ones
    /// Use case: Statistics, history view
    func fetchAllHabits() async throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetches only active (non-archived) habits
    /// Use case: Home screen habit list
    func fetchActiveHabits() async throws -> [Habit] {
        // Predicate: archivedAt == nil means habit is active
        let predicate = #Predicate<Habit> { habit in
            habit.archivedAt == nil
        }
        
        var descriptor = FetchDescriptor<Habit>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - CRUD Operations
    
    /// Adds a new habit to the database
    func addHabit(_ habit: Habit) async throws {
        modelContext.insert(habit)
        try modelContext.save()
    }
    
    /// Updates an existing habit
    /// SwiftData tracks changes automatically, we just need to save
    func updateHabit(_ habit: Habit) async throws {
        try modelContext.save()
    }
    
    /// Soft delete: Sets archivedAt date instead of removing
    /// Preserves historical data for statistics
    func archiveHabit(_ habit: Habit) async throws {
        habit.archivedAt = Date.now
        try modelContext.save()
    }
    
    /// Hard delete: Permanently removes habit and all completions
    /// Use with caution - data cannot be recovered
    func deleteHabit(_ habit: Habit) async throws {
        modelContext.delete(habit)
        try modelContext.save()
    }
    
    // MARK: - Completion Operations
    
    /// Toggles completion status for a habit on a specific date
    /// If completed: removes the completion
    /// If not completed: adds a new completion
    func toggleCompletion(for habit: Habit, on date: Date) async throws {
        let targetDate = date.startOfDay
        
        // Check if completion exists for this date
        if let existingIndex = habit.completions.firstIndex(where: { 
            $0.date.startOfDay == targetDate 
        }) {
            // Remove existing completion (uncomplete)
            let completion = habit.completions[existingIndex]
            habit.completions.remove(at: existingIndex)
            modelContext.delete(completion)
        } else {
            // Add new completion
            let completion = Completion(date: targetDate, habit: habit)
            habit.completions.append(completion)
            modelContext.insert(completion)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Streak Calculations
    
    /// Calculates current streak ending today or yesterday
    /// Algorithm: Walk backwards from today, count consecutive completed days
    func calculateCurrentStreak(for habit: Habit) async -> Int {
        let today = Date.now.startOfDay
        let completedDates = Set(habit.completions.map { $0.date.startOfDay })
        
        // If not completed today, check if completed yesterday
        // This allows streak to persist until end of day
        var checkDate = today
        if !completedDates.contains(today) {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
            if !completedDates.contains(yesterday) {
                return 0 // Streak broken
            }
            checkDate = yesterday
        }
        
        // Count consecutive days backwards
        var streak = 0
        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }
        
        return streak
    }
    
    /// Calculates the longest streak in habit history
    /// Algorithm: Find all streaks, return maximum
    func calculateLongestStreak(for habit: Habit) async -> Int {
        guard !habit.completions.isEmpty else { return 0 }
        
        // Sort completion dates
        let sortedDates = habit.completions
            .map { $0.date.startOfDay }
            .sorted()
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i - 1]
            let currentDate = sortedDates[i]
            
            // Check if dates are consecutive
            let dayDifference = Calendar.current.dateComponents(
                [.day],
                from: previousDate,
                to: currentDate
            ).day ?? 0
            
            if dayDifference == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if dayDifference > 1 {
                currentStreak = 1 // Reset streak
            }
            // dayDifference == 0 means duplicate date, skip
        }
        
        return longestStreak
    }
}

// MARK: - Mock Service for Previews & Testing
#if DEBUG
@MainActor
final class MockHabitService: HabitServiceProtocol {
    var habits: [Habit] = []
    var shouldFail = false
    
    func fetchAllHabits() async throws -> [Habit] {
        if shouldFail { throw ServiceError.fetchFailed }
        return habits
    }
    
    func fetchActiveHabits() async throws -> [Habit] {
        if shouldFail { throw ServiceError.fetchFailed }
        return habits.filter { $0.archivedAt == nil }
    }
    
    func addHabit(_ habit: Habit) async throws {
        if shouldFail { throw ServiceError.saveFailed }
        habits.append(habit)
    }
    
    func updateHabit(_ habit: Habit) async throws {
        if shouldFail { throw ServiceError.saveFailed }
    }
    
    func archiveHabit(_ habit: Habit) async throws {
        habit.archivedAt = .now
    }
    
    func deleteHabit(_ habit: Habit) async throws {
        habits.removeAll { $0.id == habit.id }
    }
    
    func toggleCompletion(for habit: Habit, on date: Date) async throws {
        // Simplified mock implementation
    }
    
    func calculateCurrentStreak(for habit: Habit) async -> Int { 5 }
    func calculateLongestStreak(for habit: Habit) async -> Int { 12 }
}

// MARK: - Service Errors
enum ServiceError: LocalizedError {
    case fetchFailed
    case saveFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed: "Could not load habits. Please try again."
        case .saveFailed: "Could not save changes. Please try again."
        case .notFound: "Habit not found."
        }
    }
}
#endif

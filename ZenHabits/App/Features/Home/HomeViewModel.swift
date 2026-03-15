//
//  HomeViewModel.swift
//  ZenHabits
//
//  MVVM: ViewModel owns state and business logic
//  View only reads from ViewModel, never mutates directly
//

import Foundation
import SwiftData

// MARK: - HomeViewModel
// @Observable: iOS 17+ macro replaces ObservableObject
// @MainActor: UI state must be updated on main thread
@Observable
@MainActor
final class HomeViewModel {
    
    // MARK: - Published State
    // private(set): Views can read, only ViewModel can write
    private(set) var habits: [Habit] = []
    private(set) var viewState: ViewState<[Habit]> = .idle
    
    // MARK: - Streak Cache
    // Cached to avoid recalculating on every view update
    private(set) var streakCache: [UUID: Int] = [:]
    
    // MARK: - UI State
    var showingAddHabit = false
    var selectedHabit: Habit?
    
    // MARK: - Dependencies
    private let habitService: HabitServiceProtocol
    
    // MARK: - Init
    // Dependency injection: Service passed in, not created internally
    // This enables testing with MockHabitService
    init(habitService: HabitServiceProtocol) {
        self.habitService = habitService
    }
    
    // MARK: - Data Loading
    
    /// Loads active habits from SwiftData
    /// Called on view appear via .task modifier
    func loadHabits() async {
        viewState = .loading
        
        do {
            habits = try await habitService.fetchActiveHabits()
            
            // Pre-calculate streaks for all habits
            await calculateAllStreaks()
            
            viewState = .success(habits)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    /// Refreshes habit list (pull-to-refresh)
    func refresh() async {
        do {
            habits = try await habitService.fetchActiveHabits()
            await calculateAllStreaks()
            viewState = .success(habits)
        } catch {
            // Keep existing data on refresh failure
            viewState = .error("Could not refresh. Pull to try again.")
        }
    }
    
    // MARK: - Habit Actions
    
    /// Toggles completion status for today
    /// Uses optimistic UI: Updates immediately, rolls back on failure
    func toggleHabit(_ habit: Habit) async {
        let today = Date.now.startOfDay
        let wasCompleted = isCompletedToday(habit)
        
        // Optimistic update: Change UI immediately
        // This makes the app feel responsive
        if wasCompleted {
            habit.completions.removeAll { $0.date.startOfDay == today }
        } else {
            let completion = Completion(date: today, habit: habit)
            habit.completions.append(completion)
        }
        
        // Update streak cache immediately
        streakCache[habit.id] = await habitService.calculateCurrentStreak(for: habit)
        
        // Persist to database
        do {
            try await habitService.toggleCompletion(for: habit, on: today)
        } catch {
            // Rollback on failure
            if wasCompleted {
                let completion = Completion(date: today, habit: habit)
                habit.completions.append(completion)
            } else {
                habit.completions.removeAll { $0.date.startOfDay == today }
            }
            streakCache[habit.id] = await habitService.calculateCurrentStreak(for: habit)
            
            viewState = .error("Could not save. Please try again.")
        }
    }
    
    /// Archives a habit (soft delete)
    func archiveHabit(_ habit: Habit) async {
        do {
            try await habitService.archiveHabit(habit)
            habits.removeAll { $0.id == habit.id }
            streakCache.removeValue(forKey: habit.id)
        } catch {
            viewState = .error("Could not archive habit.")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if habit is completed for today
    func isCompletedToday(_ habit: Habit) -> Bool {
        let today = Date.now.startOfDay
        return habit.completions.contains { $0.date.startOfDay == today }
    }
    
    /// Gets cached streak for habit
    func streak(for habit: Habit) -> Int {
        streakCache[habit.id] ?? 0
    }
    
    /// Calculates and caches streaks for all loaded habits
    private func calculateAllStreaks() async {
        for habit in habits {
            let streak = await habitService.calculateCurrentStreak(for: habit)
            streakCache[habit.id] = streak
        }
    }
}

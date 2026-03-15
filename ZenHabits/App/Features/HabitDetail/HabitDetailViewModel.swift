//
//  HabitDetailViewModel.swift
//  ZenHabits
//
//  MVVM: Manages detail view state and statistics calculations
//  Pure Engineering: Robust date calculations using Calendar API
//

import Foundation
import SwiftUI

// MARK: - Calendar Day Model
// Represents a single day in the calendar grid
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    let isCompleted: Bool
    let isToday: Bool
    let isFuture: Bool
    
    /// Day number (1-31)
    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - Monthly Stats
// Aggregated data for charts
struct MonthlyStats: Identifiable {
    let id = UUID()
    let month: Date
    let completionCount: Int
    
    /// Short month name (Jan, Feb, etc.)
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }
}

// MARK: - HabitDetailViewModel
@Observable
@MainActor
final class HabitDetailViewModel {
    
    // MARK: - Input
    let habit: Habit
    
    // MARK: - Computed Stats
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var totalCompletions: Int = 0
    private(set) var completionRate: Double = 0.0
    
    // MARK: - Calendar Data
    private(set) var calendarDays: [CalendarDay] = []
    private(set) var displayedMonth: Date = Date()
    private(set) var monthlyStats: [MonthlyStats] = []
    
    // MARK: - Dependencies
    private let habitService: HabitServiceProtocol
    private let calendar = Calendar.current
    
    // MARK: - Init
    init(habit: Habit, habitService: HabitServiceProtocol) {
        self.habit = habit
        self.habitService = habitService
        
        // Initial calculations
        Task {
            await calculateAllStats()
            generateCalendarDays(for: Date())
            generateMonthlyStats()
        }
    }
    
    // MARK: - Statistics Calculations
    
    /// Calculates all statistics for the habit
    func calculateAllStats() async {
        currentStreak = await habitService.calculateCurrentStreak(for: habit)
        bestStreak = await habitService.calculateLongestStreak(for: habit)
        totalCompletions = habit.completions.count
        
        // Calculate completion rate (completions / days since creation)
        let daysSinceCreation = calendar.dateComponents(
            [.day],
            from: habit.createdAt.startOfDay,
            to: Date().startOfDay
        ).day ?? 1
        
        if daysSinceCreation > 0 {
            completionRate = Double(totalCompletions) / Double(daysSinceCreation + 1)
        }
    }
    
    // MARK: - Calendar Generation
    
    /// Generates calendar days for a specific month
    func generateCalendarDays(for month: Date) {
        displayedMonth = month
        calendarDays = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return }
        
        let today = Date().startOfDay
        let completedDates = Set(habit.completions.map { $0.date.startOfDay })
        
        // Start from the first day of the week containing the first day of month
        var currentDate = monthFirstWeek.start
        
        // Generate 6 weeks of days (42 days max)
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: month, toGranularity: .month)
            let isToday = calendar.isDateInToday(currentDate)
            let isFuture = currentDate > today
            let isCompleted = completedDates.contains(currentDate.startOfDay)
            
            let day = CalendarDay(
                date: currentDate,
                isCurrentMonth: isCurrentMonth,
                isCompleted: isCompleted,
                isToday: isToday,
                isFuture: isFuture
            )
            
            calendarDays.append(day)
            
            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
            
            // Stop if we've completed the month and filled the week
            if !isCurrentMonth && calendar.component(.weekday, from: currentDate) == calendar.firstWeekday {
                break
            }
        }
    }
    
    /// Navigates to previous month
    func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        generateCalendarDays(for: newMonth)
    }
    
    /// Navigates to next month
    func nextMonth() {
        let today = Date()
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth),
              newMonth <= today
        else { return }
        generateCalendarDays(for: newMonth)
    }
    
    /// Checks if we can navigate to next month
    var canGoToNextMonth: Bool {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        return newMonth <= Date()
    }
    
    /// Formatted month/year string
    var displayedMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    // MARK: - Monthly Stats for Chart
    
    /// Generates last 6 months of completion data for bar chart
    func generateMonthlyStats() {
        monthlyStats = []
        let today = Date()
        
        for monthOffset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthDate)
            else { continue }
            
            // Count completions in this month
            let completionsInMonth = habit.completions.filter { completion in
                completion.date >= monthInterval.start && completion.date < monthInterval.end
            }.count
            
            monthlyStats.append(MonthlyStats(
                month: monthDate,
                completionCount: completionsInMonth
            ))
        }
    }
    
    // MARK: - Actions
    
    /// Toggles completion for a specific date (from calendar tap)
    func toggleCompletion(for date: Date) async {
        // Don't allow future dates
        guard date.startOfDay <= Date().startOfDay else { return }
        
        do {
            try await habitService.toggleCompletion(for: habit, on: date)
            
            // Refresh stats and calendar
            await calculateAllStats()
            generateCalendarDays(for: displayedMonth)
            generateMonthlyStats()
        } catch {
            // Error handling - could add error state here
            print("Failed to toggle completion: \(error)")
        }
    }
    
    /// Deletes the habit
    func deleteHabit() async throws {
        try await habitService.deleteHabit(habit)
    }
    
    /// Archives the habit (soft delete)
    func archiveHabit() async throws {
        try await habitService.archiveHabit(habit)
    }
}

//
//  Date+Extensions.swift
//  ZenHabits
//
//  Date utilities for habit tracking and streak calculation.
//

import Foundation

// MARK: - Date + Habit Tracking
extension Date {
    
    // MARK: - Day Normalization
    
    /// Returns the start of the day (00:00:00) for this date.
    /// Critical for consistent streak calculations.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Returns the end of the day (23:59:59) for this date.
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    // MARK: - Day Comparisons
    
    /// True if this date is today (ignoring time)
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// True if this date is yesterday (ignoring time)
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// True if this date is in the current week
    var isInCurrentWeek: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .weekOfYear)
    }
    
    /// True if this date is in the current month
    var isInCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: .now, toGranularity: .month)
    }
    
    // MARK: - Date Arithmetic
    
    /// Returns a date by adding the specified number of days.
    /// Negative values subtract days.
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Returns a date by adding the specified number of weeks.
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    /// Returns the number of days between this date and another date.
    /// Positive if `other` is in the future, negative if in the past.
    func days(until other: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self.startOfDay, to: other.startOfDay)
        return components.day ?? 0
    }
    
    /// Returns the number of days since this date (positive if in the past)
    var daysAgo: Int {
        days(until: .now) * -1
    }
    
    // MARK: - Week Helpers
    
    /// Returns the start of the week containing this date (Sunday or Monday based on locale)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns all dates in the week containing this date
    var datesInWeek: [Date] {
        let start = startOfWeek
        return (0..<7).compactMap { start.adding(days: $0) }
    }
    
    // MARK: - Month Helpers
    
    /// Returns the start of the month containing this date
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns all dates in the month containing this date
    var datesInMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self) ?? 1..<2
        let start = startOfMonth
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }
    
    /// Number of days in the month containing this date
    var numberOfDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }
    
    // MARK: - Formatting
    
    /// Returns a relative description (e.g., "Today", "Yesterday", "3 days ago")
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: self, relativeTo: .now)
    }
    
    /// Formats date as "Mon, Jan 1"
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: self)
    }
    
    /// Formats date as "January 2024"
    var monthYearFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - Date + Streak Calculation
extension Date {
    
    /// Generates an array of dates from this date to another date (inclusive).
    /// Used for streak visualization.
    func dates(through endDate: Date) -> [Date] {
        var dates: [Date] = []
        var current = self.startOfDay
        let end = endDate.startOfDay
        
        while current <= end {
            dates.append(current)
            current = current.adding(days: 1)
        }
        
        return dates
    }
}

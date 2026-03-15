//
//  CalendarHeatmap.swift
//  ZenHabits
//
//  GitHub-style contribution calendar for habit tracking
//  Design: Minimalist grid with color intensity based on completion
//

import SwiftUI

struct CalendarHeatmap: View {
    
    // MARK: - Properties
    let days: [CalendarDay]
    let accentColor: Color
    let onDayTap: (Date) -> Void
    
    // MARK: - Layout
    // 7 columns for days of week
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            weekdayHeader
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days) { day in
                    dayCell(day)
                }
            }
        }
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    /// Returns localized weekday symbols starting from locale's first weekday
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1 // 0-indexed
        
        // Rotate array to start from first weekday
        return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
    }
    
    // MARK: - Day Cell
    private func dayCell(_ day: CalendarDay) -> some View {
        Button {
            if !day.isFuture && day.isCurrentMonth {
                // Haptic feedback - different for completing vs uncompleting
                HapticManager.habitToggle(completing: !day.isCompleted)
                onDayTap(day.date)
            }
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(cellBackgroundColor(for: day))
                    .aspectRatio(1, contentMode: .fit)
                
                // Day number (only for current month)
                if day.isCurrentMonth {
                    Text("\(day.dayNumber)")
                        .font(.caption2)
                        .fontWeight(day.isToday ? .bold : .regular)
                        .foregroundStyle(cellTextColor(for: day))
                }
                
                // Today indicator
                if day.isToday && day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(accentColor, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(day.isFuture || !day.isCurrentMonth)
        .accessibilityLabel(accessibilityLabel(for: day))
        .accessibilityHint(day.isCurrentMonth && !day.isFuture ? "Double tap to toggle completion" : "")
    }
    
    // MARK: - Cell Styling
    
    private func cellBackgroundColor(for day: CalendarDay) -> Color {
        if !day.isCurrentMonth {
            // Outside current month - nearly invisible
            return Color.clear
        }
        
        if day.isFuture {
            // Future dates - subtle disabled look
            return colorScheme == .dark 
                ? Color(.systemGray6).opacity(0.3)
                : Color(.systemGray6).opacity(0.5)
        }
        
        if day.isCompleted {
            // Completed - habit accent color
            return accentColor
        }
        
        // Not completed - subtle background
        return colorScheme == .dark 
            ? Color(.systemGray5)
            : Color(.systemGray6)
    }
    
    private func cellTextColor(for day: CalendarDay) -> Color {
        if day.isFuture {
            return .secondary.opacity(0.5)
        }
        
        if day.isCompleted {
            return .white
        }
        
        if day.isToday {
            return accentColor
        }
        
        return .primary
    }
    
    private func accessibilityLabel(for day: CalendarDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateString = formatter.string(from: day.date)
        
        if !day.isCurrentMonth {
            return "Outside current month"
        }
        
        if day.isFuture {
            return "\(dateString), future date"
        }
        
        let status = day.isCompleted ? "completed" : "not completed"
        let todayIndicator = day.isToday ? ", today" : ""
        
        return "\(dateString)\(todayIndicator), \(status)"
    }
}

// MARK: - Compact Heatmap Variant
// A more compact version for widgets or small displays
struct CompactCalendarHeatmap: View {
    
    let days: [CalendarDay]
    let accentColor: Color
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(days.suffix(35)) { day in // Last 5 weeks
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(day.isCompleted ? accentColor : Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    // Generate sample days for current month
    let sampleDays: [CalendarDay] = (0..<35).map { offset in
        let date = calendar.date(byAdding: .day, value: offset - 14, to: today) ?? today
        return CalendarDay(
            date: date,
            isCurrentMonth: true,
            isCompleted: Bool.random() && offset < 14,
            isToday: offset == 14,
            isFuture: offset > 14
        )
    }
    
    return VStack(spacing: 32) {
        CalendarHeatmap(
            days: sampleDays,
            accentColor: .purple,
            onDayTap: { date in print("Tapped: \(date)") }
        )
        .padding()
        
        CompactCalendarHeatmap(
            days: sampleDays,
            accentColor: .orange
        )
        .frame(height: 100)
        .padding()
    }
}

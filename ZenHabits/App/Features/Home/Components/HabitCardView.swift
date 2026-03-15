//
//  HabitCardView.swift
//  ZenHabits
//
//  Reusable component: Displays a single habit with streak info
//  Design: "Alive Minimalism" - warm cards with subtle depth and satisfying interactions
//

import SwiftUI

struct HabitCardView: View {
    
    // MARK: - Properties
    let habit: Habit
    let streak: Int
    let isCompletedToday: Bool
    let onToggle: () -> Void
    let onTap: () -> Void
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Animation State
    @State private var isPressed = false
    @State private var checkmarkScale: CGFloat = 1.0
    @State private var cardScale: CGFloat = 1.0
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 16) {
            // Left: Habit Icon
            habitIcon
            
            // Middle: Title & Streak
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                streakBadge
            }
            
            Spacer(minLength: 8)
            
            // Right: Completion Button
            completionButton
        }
        .padding(16)
        .background(cardBackground)
        .scaleEffect(cardScale)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.title), \(streakAccessibilityText), \(isCompletedToday ? "completed" : "not completed")")
        .accessibilityHint("Double tap for details, or activate the checkmark to toggle completion")
    }
    
    // MARK: - Habit Icon
    private var habitIcon: some View {
        ZStack {
            // Outer glow when completed
            if isCompletedToday {
                Circle()
                    .fill(habit.color.opacity(0.15))
                    .frame(width: 56, height: 56)
            }
            
            // Main circle
            Circle()
                .fill(
                    isCompletedToday
                        ? habit.color.opacity(0.2)
                        : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                )
                .frame(width: 48, height: 48)
            
            // Emoji
            Text(habit.emoji)
                .font(.title2)
        }
    }
    
    // MARK: - Streak Badge
    private var streakBadge: some View {
        HStack(spacing: 4) {
            if streak > 0 {
                // Flame icon with animation for high streaks
                Image(systemName: streak >= 7 ? "flame.fill" : "flame")
                    .font(.caption)
                    .foregroundStyle(streakColor)
                    .symbolEffect(.bounce, value: isCompletedToday)
                
                Text("\(streak) day streak")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else if isCompletedToday {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                
                Text("Started today!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tap to begin")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    /// Streak color based on streak length
    private var streakColor: Color {
        switch streak {
        case 0..<3:
            return .orange.opacity(0.7)
        case 3..<7:
            return .orange
        case 7..<30:
            return .red
        default:
            return .red
        }
    }
    
    private var streakAccessibilityText: String {
        if streak > 0 {
            return "\(streak) day streak"
        } else if isCompletedToday {
            return "started today"
        } else {
            return "no streak"
        }
    }
    
    // MARK: - Completion Button
    private var completionButton: some View {
        Button {
            // Haptic feedback
            HapticManager.habitToggle(completing: !isCompletedToday)
            
            // Animate checkmark
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                checkmarkScale = 0.7
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    checkmarkScale = 1.1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
            }
            
            onToggle()
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(isCompletedToday ? habit.color : Color.clear)
                    .frame(width: 44, height: 44)
                
                // Border for uncompleted state
                Circle()
                    .stroke(
                        isCompletedToday ? Color.clear : habit.color.opacity(0.4),
                        lineWidth: 2.5
                    )
                    .frame(width: 44, height: 44)
                
                // Checkmark or plus
                if isCompletedToday {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(habit.color.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompletedToday ? "Mark as incomplete" : "Mark as complete")
    }
    
    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(cardFillColor)
            .shadow(
                color: shadowColor,
                radius: isCompletedToday ? 8 : 5,
                x: 0,
                y: isCompletedToday ? 4 : 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    private var cardFillColor: Color {
        if isCompletedToday {
            return colorScheme == .dark
                ? Color(.systemGray6)
                : Color(.systemBackground)
        } else {
            return colorScheme == .dark
                ? Color(.systemGray6)
                : Color(.systemBackground)
        }
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return .clear
        }
        return isCompletedToday
            ? habit.color.opacity(0.15)
            : .black.opacity(0.04)
    }
    
    private var borderColor: Color {
        if isCompletedToday {
            return habit.color.opacity(colorScheme == .dark ? 0.3 : 0.2)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.04)
    }
}

// MARK: - Preview
#Preview("Various States") {
    ScrollView {
        VStack(spacing: 16) {
            // Completed with streak
            HabitCardView(
                habit: Habit(
                    title: "Morning Meditation",
                    emoji: "🧘",
                    colorHex: "5E5CE6"
                ),
                streak: 12,
                isCompletedToday: true,
                onToggle: {},
                onTap: {}
            )
            
            // Not completed with streak
            HabitCardView(
                habit: Habit(
                    title: "Read 30 minutes",
                    emoji: "📚",
                    colorHex: "FF9500"
                ),
                streak: 5,
                isCompletedToday: false,
                onToggle: {},
                onTap: {}
            )
            
            // New habit, not started
            HabitCardView(
                habit: Habit(
                    title: "Drink 8 Glasses of Water",
                    emoji: "💧",
                    colorHex: "32ADE6"
                ),
                streak: 0,
                isCompletedToday: false,
                onToggle: {},
                onTap: {}
            )
            
            // New habit, just completed
            HabitCardView(
                habit: Habit(
                    title: "Go to Gym",
                    emoji: "💪",
                    colorHex: "34C759"
                ),
                streak: 0,
                isCompletedToday: true,
                onToggle: {},
                onTap: {}
            )
            
            // Long title
            HabitCardView(
                habit: Habit(
                    title: "Practice Piano for at least 30 minutes every single day",
                    emoji: "🎹",
                    colorHex: "AF52DE"
                ),
                streak: 30,
                isCompletedToday: false,
                onToggle: {},
                onTap: {}
            )
        }
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}

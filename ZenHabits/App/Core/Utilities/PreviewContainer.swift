//
//  PreviewContainer.swift
//  ZenHabits
//
//  Helper for Xcode Previews and testing with pre-populated data
//  Uses in-memory storage to avoid polluting the real database
//

import Foundation
import SwiftData

// MARK: - Preview Container
/// Provides a pre-configured ModelContainer with sample data for previews
@MainActor
enum PreviewContainer {
    
    // MARK: - Sample Container
    /// A ModelContainer with sample habits and completions for Xcode Previews
    static var sample: ModelContainer {
        let schema = Schema([Habit.self, Completion.self, SleepLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            
            // Insert sample data
            insertSampleData(into: container.mainContext)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
    
    // MARK: - Empty Container
    /// An empty in-memory container for testing edge cases
    static var empty: ModelContainer {
        let schema = Schema([Habit.self, Completion.self, SleepLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create empty container: \(error)")
        }
    }
    
    // MARK: - Sample Data Insertion
    private static func insertSampleData(into context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
        // Create a reminder time at 9:00 AM
        var morningComponents = DateComponents()
        morningComponents.hour = 9
        morningComponents.minute = 0
        let morningReminder = calendar.date(from: morningComponents)
        
        // Create a reminder time at 8:00 PM
        var eveningComponents = DateComponents()
        eveningComponents.hour = 20
        eveningComponents.minute = 0
        let eveningReminder = calendar.date(from: eveningComponents)
        
        // MARK: Habit 1 - Meditation (Essential with reminder, Great streak)
        let meditation = Habit(
            title: "Morning Meditation",
            emoji: "🧘",
            colorHex: "5E5CE6", // Indigo
            frequency: .daily,
            createdAt: calendar.date(byAdding: .day, value: -45, to: today) ?? today,
            isCritical: true,
            reminderTime: morningReminder
        )
        context.insert(meditation)
        
        // Add completions for last 12 days (active streak)
        for dayOffset in 0..<12 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let completion = Completion(date: date.startOfDay, habit: meditation)
                context.insert(completion)
                meditation.completions.append(completion)
            }
        }
        
        // Add some older completions with gaps
        for dayOffset in [15, 16, 17, 20, 21, 25, 26, 27, 28, 30, 35, 36, 37, 38, 39, 40] {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let completion = Completion(date: date.startOfDay, habit: meditation)
                context.insert(completion)
                meditation.completions.append(completion)
            }
        }
        
        // MARK: Habit 2 - Reading (Essential, Moderate streak)
        let reading = Habit(
            title: "Read 30 Minutes",
            emoji: "📚",
            colorHex: "FF9500", // Orange
            frequency: .daily,
            createdAt: calendar.date(byAdding: .day, value: -30, to: today) ?? today,
            isCritical: true,
            reminderTime: eveningReminder
        )
        context.insert(reading)
        
        // Add completions for last 5 days
        for dayOffset in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let completion = Completion(date: date.startOfDay, habit: reading)
                context.insert(completion)
                reading.completions.append(completion)
            }
        }
        
        // Scattered older completions
        for dayOffset in [7, 8, 10, 12, 14, 15, 18, 20, 22, 25] {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let completion = Completion(date: date.startOfDay, habit: reading)
                context.insert(completion)
                reading.completions.append(completion)
            }
        }
        
        // MARK: Habit 3 - Water (Routine, Broken streak)
        let water = Habit(
            title: "Drink 8 Glasses",
            emoji: "💧",
            colorHex: "32ADE6", // Cyan
            frequency: .daily,
            createdAt: calendar.date(byAdding: .day, value: -60, to: today) ?? today,
            isCritical: false,
            reminderTime: nil
        )
        context.insert(water)
        
        // No completion today (streak broken)
        for dayOffset in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 15, 16, 17, 20, 25, 30, 35, 40, 45, 50] {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let completion = Completion(date: date.startOfDay, habit: water)
                context.insert(completion)
                water.completions.append(completion)
            }
        }
        
        // MARK: Habit 4 - Gym (Routine with reminder, Weekday habit)
        let gym = Habit(
            title: "Go to Gym",
            emoji: "💪",
            colorHex: "34C759", // Green
            frequency: .weekly(days: [2, 3, 4, 5, 6]), // Mon-Fri
            createdAt: calendar.date(byAdding: .day, value: -90, to: today) ?? today,
            isCritical: false,
            reminderTime: morningReminder
        )
        context.insert(gym)
        
        // Add completions for weekdays only
        for dayOffset in 0..<60 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                // Skip weekends (1 = Sunday, 7 = Saturday)
                if weekday != 1 && weekday != 7 {
                    // ~70% completion rate on weekdays
                    if Int.random(in: 0..<10) < 7 {
                        let completion = Completion(date: date.startOfDay, habit: gym)
                        context.insert(completion)
                        gym.completions.append(completion)
                    }
                }
            }
        }
        
        // MARK: Habit 5 - New habit (Routine, No completions yet)
        let journal = Habit(
            title: "Write Journal",
            emoji: "✍️",
            colorHex: "AF52DE", // Purple
            frequency: .daily,
            createdAt: today, // Created today
            isCritical: false,
            reminderTime: nil
        )
        context.insert(journal)
        // No completions - tests empty state
        
        // MARK: Sample Sleep Log for Today
        var bedTimeComponents = calendar.dateComponents([.year, .month, .day], from: today)
        bedTimeComponents.day! -= 1
        bedTimeComponents.hour = 23
        bedTimeComponents.minute = 15
        let bedTime = calendar.date(from: bedTimeComponents) ?? today
        
        var wakeTimeComponents = calendar.dateComponents([.year, .month, .day], from: today)
        wakeTimeComponents.hour = 7
        wakeTimeComponents.minute = 30
        let wakeTime = calendar.date(from: wakeTimeComponents) ?? today
        
        let sleepLog = SleepLog(
            date: today,
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: 8,
            hasDreamed: true,
            dreamContent: "Had a vivid dream about flying over mountains",
            mood: .great
        )
        context.insert(sleepLog)
        
        // Save all changes
        do {
            try context.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }
    }
}

// MARK: - Sample Habits (Standalone)
/// Individual sample habits for component previews
enum SampleHabits {
    
    @MainActor
    static var meditation: Habit {
        Habit(
            title: "Morning Meditation",
            emoji: "🧘",
            colorHex: "5E5CE6",
            isCritical: true,
            reminderTime: Date()
        )
    }
    
    @MainActor
    static var reading: Habit {
        Habit(
            title: "Read 30 Minutes",
            emoji: "📚",
            colorHex: "FF9500",
            isCritical: true
        )
    }
    
    @MainActor
    static var water: Habit {
        Habit(
            title: "Drink 8 Glasses",
            emoji: "💧",
            colorHex: "32ADE6"
        )
    }
    
    @MainActor
    static var gym: Habit {
        Habit(
            title: "Go to Gym",
            emoji: "💪",
            colorHex: "34C759",
            reminderTime: Date()
        )
    }
}

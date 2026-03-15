//
//  SleepLog.swift
//  
//
//  Core domain model for sleep tracking
//  Design: Rich data capture for sleep patterns, quality, dreams, and mood
//

import Foundation
import SwiftData

// MARK: - Sleep Mood
/// Represents morning mood after waking
enum SleepMood: String, CaseIterable, Codable, Sendable {
    case terrible = "😫"
    case bad = "😔"
    case okay = "😐"
    case good = "🙂"
    case great = "😊"
    case amazing = "🤩"
    
    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad: return "Bad"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        case .amazing: return "Amazing"
        }
    }
    
    var color: String {
        switch self {
        case .terrible: return "FF3B30"  // Red
        case .bad: return "FF9500"        // Orange
        case .okay: return "FFCC00"       // Yellow
        case .good: return "34C759"       // Green
        case .great: return "32ADE6"      // Cyan
        case .amazing: return "AF52DE"    // Purple
        }
    }
}

// MARK: - SleepLog Model
/// Records a single night's sleep data
///
/// Design Decisions:
/// - `date` is normalized to start-of-day for the wake date (today)
/// - `bedTime` is typically yesterday evening
/// - `wakeTime` is typically today morning
/// - Quality is stored as 1-10 scale for flexibility
/// - Mood stored as raw string for SwiftData compatibility
@Model
final class SleepLog {
    
    // MARK: - Properties
    
    /// Unique identifier
    var id: UUID
    
    /// The date this log is for (normalized to wake date's start of day)
    /// Used as a unique key - only one log per day
    var date: Date
    
    /// When user went to bed (typically previous evening)
    var bedTime: Date
    
    /// When user woke up (typically this morning)
    var wakeTime: Date
    
    /// Sleep quality rating from 1-10
    /// 1 = Terrible, 10 = Amazing
    var quality: Int
    
    /// Whether the user remembers dreaming
    var hasDreamed: Bool
    
    /// Optional dream description/notes
    var dreamContent: String?
    
    /// Morning mood stored as emoji string
    /// Access via `sleepMood` computed property
    var moodRaw: String
    
    /// Timestamp when this log was created
    var createdAt: Date
    
    // MARK: - Computed Properties
    
    /// Sleep duration as TimeInterval
    var duration: TimeInterval {
        wakeTime.timeIntervalSince(bedTime)
    }
    
    /// Formatted duration string (e.g., "7h 30m")
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Duration in hours (decimal)
    var durationHours: Double {
        duration / 3600
    }
    
    /// Typed mood accessor
    var sleepMood: SleepMood {
        get {
            SleepMood(rawValue: moodRaw) ?? .okay
        }
        set {
            moodRaw = newValue.rawValue
        }
    }
    
    /// Quality as descriptive text
    var qualityDescription: String {
        switch quality {
        case 1...2: return "Poor"
        case 3...4: return "Fair"
        case 5...6: return "Average"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return "Unknown"
        }
    }
    
    /// Whether this is a "good" night's sleep (7+ hours, 7+ quality)
    var isGoodSleep: Bool {
        durationHours >= 7 && quality >= 7
    }
    
    // MARK: - Initialization
    
    /// Creates a new SleepLog
    ///
    /// - Parameters:
    ///   - date: The date this log is for (default: today)
    ///   - bedTime: When user went to bed
    ///   - wakeTime: When user woke up
    ///   - quality: Sleep quality 1-10 (default: 5)
    ///   - hasDreamed: Whether user dreamed (default: false)
    ///   - dreamContent: Optional dream description
    ///   - mood: Morning mood (default: .okay)
    init(
        id: UUID = UUID(),
        date: Date = .now,
        bedTime: Date,
        wakeTime: Date,
        quality: Int = 5,
        hasDreamed: Bool = false,
        dreamContent: String? = nil,
        mood: SleepMood = .okay
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = min(max(quality, 1), 10) // Clamp to 1-10
        self.hasDreamed = hasDreamed
        self.dreamContent = dreamContent
        self.moodRaw = mood.rawValue
        self.createdAt = .now
    }
}

// MARK: - SleepLog + Comparable
extension SleepLog: Comparable {
    static func < (lhs: SleepLog, rhs: SleepLog) -> Bool {
        lhs.date < rhs.date
    }
}

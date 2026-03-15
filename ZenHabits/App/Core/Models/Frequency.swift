//
//  Frequency.swift
//  ZenHabits
//
//  Defines how often a habit should be completed.
//

import Foundation

// MARK: - Frequency
/// Represents the recurrence pattern for a habit.
///
/// Design Decisions:
/// - Enum with associated values for flexible scheduling
/// - Manual Codable conformance for SwiftData persistence
/// - Hashable for use in Sets and dictionaries
/// - Sendable for Swift 6 concurrency safety
enum Frequency: Hashable, Sendable {
    
    /// Complete every day
    case daily
    
    /// Complete on specific days of the week (stored as Int raw values 1-7)
    /// 1 = Sunday, 2 = Monday, ... 7 = Saturday (matches Calendar.weekday)
    case weekly(days: Set<Int>)
    
    /// Complete every N days
    /// Example: .custom(3) - every 3 days
    case custom(Int)
}

// MARK: - Frequency + Codable
/// Manual Codable implementation required because of associated values
/// Uses nonisolated methods for Swift 6 Sendable compliance
extension Frequency: Codable {
    
    // Coding keys for JSON structure
    private enum CodingKeys: String, CodingKey {
        case type
        case days
        case interval
    }
    
    // Type discriminator
    private enum FrequencyType: String, Codable {
        case daily
        case weekly
        case custom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FrequencyType.self, forKey: .type)
        
        switch type {
        case .daily:
            self = .daily
            
        case .weekly:
            let daysArray = try container.decode([Int].self, forKey: .days)
            self = .weekly(days: Set(daysArray))
            
        case .custom:
            let interval = try container.decode(Int.self, forKey: .interval)
            self = .custom(interval)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .daily:
            try container.encode(FrequencyType.daily, forKey: .type)
            
        case .weekly(let days):
            try container.encode(FrequencyType.weekly, forKey: .type)
            try container.encode(Array(days).sorted(), forKey: .days)
            
        case .custom(let interval):
            try container.encode(FrequencyType.custom, forKey: .type)
            try container.encode(interval, forKey: .interval)
        }
    }
}

// MARK: - Frequency + Display
extension Frequency {
    
    /// Human-readable description for UI display
    var displayName: String {
        switch self {
        case .daily:
            return "Every day"
            
        case .weekly(let days):
            if days.count == 7 {
                return "Every day"
            } else if days.count == 5 && days == Set([2, 3, 4, 5, 6]) {
                return "Weekdays"
            } else if days.count == 2 && days == Set([1, 7]) {
                return "Weekends"
            } else {
                // Convert Int days to abbreviated names
                let dayNames = days.sorted().compactMap { dayNumber -> String? in
                    switch dayNumber {
                    case 1: return "Sun"
                    case 2: return "Mon"
                    case 3: return "Tue"
                    case 4: return "Wed"
                    case 5: return "Thu"
                    case 6: return "Fri"
                    case 7: return "Sat"
                    default: return nil
                    }
                }
                return dayNames.joined(separator: ", ")
            }
            
        case .custom(let interval):
            if interval == 1 {
                return "Every day"
            } else {
                return "Every \(interval) days"
            }
        }
    }
    
    /// Short label for compact UI (e.g., habit cards)
    var shortLabel: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly(let days):
            if days.count == 7 {
                return "Daily"
            }
            return "\(days.count) days/week"
        case .custom(let interval):
            return "Every \(interval)d"
        }
    }
}

// MARK: - Frequency Encoding Helpers
/// Thread-safe encoding/decoding helpers for use with SwiftData
extension Frequency {
    
    /// Encodes the frequency to Data for storage
    /// Returns empty Data if encoding fails
    var encodedData: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }
    
    /// Decodes a Frequency from Data
    /// Returns .daily if decoding fails
    static func decode(from data: Data) -> Frequency {
        (try? JSONDecoder().decode(Frequency.self, from: data)) ?? .daily
    }
}

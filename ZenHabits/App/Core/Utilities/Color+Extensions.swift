//
//  Color+Extensions.swift
//  ZenHabits
//
//  SwiftUI Color utilities for hex conversion and predefined palettes.
//

import SwiftUI

// MARK: - Color + Hex Conversion
extension Color {
    
    /// Creates a Color from a hex string.
    ///
    /// Supports formats:
    /// - "#RRGGBB"
    /// - "RRGGBB"
    /// - "#RRGGBBAA"
    /// - "RRGGBBAA"
    ///
    /// - Parameter hex: Hexadecimal color string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Converts the Color to a hex string (e.g., "#FF5733").
    /// Returns nil if conversion fails.
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r: CGFloat = components.count > 0 ? components[0] : 0
        let g: CGFloat = components.count > 1 ? components[1] : 0
        let b: CGFloat = components.count > 2 ? components[2] : 0
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
    }
}

// MARK: - Habit Color Palette
/// Predefined colors for habit customization.
/// Curated for accessibility (good contrast in both light/dark modes).
extension Color {
    
    /// Predefined habit colors as hex strings for SwiftData storage
    enum HabitPalette {
        
        /// All available colors as hex strings
        static let allHex: [String] = [
            "#FF6B6B",  // Coral Red
            "#FF8C42",  // Tangerine
            "#FFD93D",  // Sunny Yellow
            "#6BCB77",  // Fresh Green
            "#4D96FF",  // Sky Blue
            "#5856D6",  // Indigo (Default)
            "#9B59B6",  // Amethyst
            "#E056FD",  // Pink
            "#636E72",  // Slate Gray
            "#2D3436",  // Charcoal
        ]
        
        /// All available colors as Color objects
        static let all: [Color] = allHex.map { Color(hex: $0) }
        
        /// Default habit color (Indigo)
        static let defaultHex: String = "#5856D6"
        static let defaultColor: Color = Color(hex: defaultHex)
        
        /// Returns a random color from the palette
        static var random: String {
            allHex.randomElement() ?? defaultHex
        }
    }
}

// MARK: - Color + Accessibility
extension Color {
    
    /// Returns a contrasting text color (white or black) based on luminance.
    /// Use this to ensure text remains readable on colored backgrounds.
    var contrastingTextColor: Color {
        guard let components = UIColor(self).cgColor.components else {
            return .primary
        }
        
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        
        // Calculate relative luminance using WCAG formula
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        
        return luminance > 0.5 ? .black : .white
    }
}

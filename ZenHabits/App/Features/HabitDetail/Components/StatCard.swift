//
//  StatCard.swift
//  ZenHabits
//
//  Reusable statistics card component
//  Design: Compact card with icon, value, and label
//

import SwiftUI

struct StatCard: View {
    
    // MARK: - Properties
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 12) {
        StatCard(
            icon: "flame.fill",
            value: "12",
            label: "Current",
            color: .orange
        )
        
        StatCard(
            icon: "trophy.fill",
            value: "28",
            label: "Best",
            color: .yellow
        )
        
        StatCard(
            icon: "checkmark.circle.fill",
            value: "156",
            label: "Total",
            color: .green
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

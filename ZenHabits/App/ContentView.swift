//
//  ContentView.swift
//  ZenHabits
//
//  Root view: Routes to the main HomeView
//  Future: Could become a TabView for multiple sections
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        // HomeView is now the main entry point
        // Future: Wrap in TabView for Statistics, Settings tabs
        HomeView()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, Completion.self], inMemory: true)
}

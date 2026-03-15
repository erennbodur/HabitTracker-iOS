//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Pure Engineering: Main entry point with SwiftData configuration
//  No analytics, no tracking, no commercial SDKs
//

import SwiftUI
import SwiftData

// MARK: - App Entry Point
@main
struct HabitTrackerApp: App {
    
    // MARK: - Onboarding State
    /// Persisted flag to track if user has completed onboarding
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // MARK: - SwiftData Container
    // modelContainer: Manages the database schema and persistence
    // Configured once at app launch, injected into environment
    var sharedModelContainer: ModelContainer = {
        // Define schema with all model types
        let schema = Schema([
            Habit.self,
            Completion.self,
            SleepLog.self  // Sleep tracking model
        ])
        
        // Configuration options
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,  // Persist to disk
            allowsSave: true
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Fatal error is acceptable here - app cannot function without database
            // In production, you might want crash reporting here
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            rootView
        }
        // Inject ModelContainer into environment
        // All child views can access via @Environment(\.modelContext)
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Root View Router
    /// Routes to Onboarding or Home based on persisted state
    @ViewBuilder
    private var rootView: some View {
        if hasSeenOnboarding {
            ContentView()
        } else {
            OnboardingView {
                // Called when user completes onboarding
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}


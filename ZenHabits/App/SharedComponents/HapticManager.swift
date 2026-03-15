//
//  HapticManager.swift
//  ZenHabits
//
//  Centralized haptic feedback controller for premium tactile UX
//  Uses UIKit feedback generators for native iOS feel
//

import UIKit

// MARK: - HapticManager
/// Singleton manager for all haptic feedback in the app
/// Centralized control allows easy customization and potential user preferences
@MainActor
final class HapticManager {
    
    // MARK: - Singleton
    static let shared = HapticManager()
    
    // MARK: - Feedback Generators
    // Pre-initialized for better performance (avoids latency on first trigger)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Init
    private init() {
        // Prepare generators for immediate response
        prepareGenerators()
    }
    
    /// Pre-warms the Taptic Engine for faster response
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Success Feedback
    /// Triggers success haptic - use for habit completion, saves, achievements
    /// Strong, satisfying feedback that rewards the user
    func triggerSuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare() // Prepare for next use
    }
    
    // MARK: - Error Feedback
    /// Triggers error haptic - use for validation failures, errors
    /// Sharp, attention-grabbing feedback
    func triggerError() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // MARK: - Warning Feedback
    /// Triggers warning haptic - use for destructive actions, confirmations
    /// Moderate intensity to draw attention without alarming
    func triggerWarning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    // MARK: - Selection Feedback
    /// Triggers selection haptic - use for picker changes, toggles
    /// Subtle tick for UI state changes
    func triggerSelection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    /// Triggers light impact - use for button taps, minor interactions
    func triggerLightImpact() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }
    
    /// Triggers medium impact - use for completing actions, card taps
    func triggerMediumImpact() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    /// Triggers heavy impact - use for major state changes, drag end
    func triggerHeavyImpact() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }
    
    /// Triggers soft impact - use for subtle confirmations
    func triggerSoftImpact() {
        impactSoft.impactOccurred()
        impactSoft.prepare()
    }
    
    /// Triggers rigid impact - use for definitive actions
    func triggerRigidImpact() {
        impactRigid.impactOccurred()
        impactRigid.prepare()
    }
    
    // MARK: - Custom Intensity Impact
    /// Triggers impact with custom intensity (0.0 - 1.0)
    /// - Parameter intensity: Strength of the haptic (0.0 = none, 1.0 = max)
    func triggerImpact(intensity: CGFloat) {
        impactMedium.impactOccurred(intensity: intensity)
        impactMedium.prepare()
    }
    
    // MARK: - Streak Celebration
    /// Special haptic pattern for streak milestones
    /// Creates a satisfying double-tap effect
    func triggerStreakCelebration() {
        Task { @MainActor in
            impactHeavy.impactOccurred()
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
            impactHeavy.prepare()
        }
    }
    
    // MARK: - Habit Completion
    /// Optimized haptic for habit completion toggle
    /// Different feedback for completing vs uncompleting
    func triggerHabitToggle(isCompleting: Bool) {
        if isCompleting {
            // Satisfying success for completing
            triggerSuccess()
        } else {
            // Softer feedback for uncompleting
            triggerSoftImpact()
        }
    }
}

// MARK: - Convenience Static Methods
/// Static accessors for cleaner call sites
extension HapticManager {
    
    static func success() {
        shared.triggerSuccess()
    }
    
    static func error() {
        shared.triggerError()
    }
    
    static func warning() {
        shared.triggerWarning()
    }
    
    static func selection() {
        shared.triggerSelection()
    }
    
    static func light() {
        shared.triggerLightImpact()
    }
    
    static func medium() {
        shared.triggerMediumImpact()
    }
    
    static func heavy() {
        shared.triggerHeavyImpact()
    }
    
    static func habitToggle(completing: Bool) {
        shared.triggerHabitToggle(isCompleting: completing)
    }
    
    static func streakCelebration() {
        shared.triggerStreakCelebration()
    }
}

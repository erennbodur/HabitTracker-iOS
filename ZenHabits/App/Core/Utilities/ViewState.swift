//
//  ViewState.swift
//  ZenHabits
//
//  Generic state management for async operations.
//

import Foundation

// MARK: - ViewState
/// Represents the state of any asynchronous operation.
///
/// Design Decisions:
/// - Generic over success type for reusability across features
/// - Provides computed helpers to reduce switch boilerplate in Views
/// - Error stored as String for simple UI display (not Error type)
///
/// Usage:
/// ```swift
/// @Observable
/// class MyViewModel {
///     private(set) var state: ViewState<[Item]> = .idle
///
///     func load() async {
///         state = .loading
///         do {
///             let items = try await service.fetch()
///             state = .success(items)
///         } catch {
///             state = .error(error.localizedDescription)
///         }
///     }
/// }
/// ```
enum ViewState<T> {
    
    /// Initial state, no operation has started
    case idle
    
    /// Operation in progress
    case loading
    
    /// Operation completed successfully with data
    case success(T)
    
    /// Operation failed with error message
    case error(String)
}

// MARK: - Computed Helpers
extension ViewState {
    
    /// True if currently loading
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    /// True if in idle state
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    
    /// Returns error message if in error state, nil otherwise
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
    
    /// Returns data if in success state, nil otherwise
    var data: T? {
        if case .success(let data) = self { return data }
        return nil
    }
    
    /// True if operation completed (success or error)
    var isComplete: Bool {
        switch self {
        case .success, .error: return true
        case .idle, .loading: return false
        }
    }
}

// MARK: - ViewState + Equatable (when T is Equatable)
extension ViewState: Equatable where T: Equatable {
    static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.success(let lhsData), .success(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

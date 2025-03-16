//
//  ARErrorManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import SwiftUI

/// Centralized error handling manager for AR-related functionality
/// Displays alerts when AR detection encounters problems and provides retry options
class ARErrorManager: ObservableObject {
    
    // Singleton instance for app-wide access to AR error handling
    static let shared = ARErrorManager()
    
    // MARK: - Published Properties

    // Controls visibility of the error alert
    @Published var showErrorAlert = false
    
    // The error message to display to the user
    @Published var errorMessage = ""
    
    // Optional closure that will be executed if the user wants to retry the failed operation
    @Published var retryAction: (() -> Void)? = nil
    
    
    /// Shows an error alert with an optional retry action
    /// - Parameters:
    ///   - message: The error message to display
    ///   - retryAction: Optional closure that will execute if user taps "Try Again"
    func showError(message: String, retryAction: (() -> Void)? = nil) {
        
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.retryAction = retryAction
            self?.showErrorAlert = true
        }
    }
}

/// SwiftUI view modifier that adds AR error alert functionality to any view
struct ARErrorAlert: ViewModifier {
    
    // Observe the shared error manager to respond to its state changes
    @ObservedObject private var errorManager = ARErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("AR Detection Error", isPresented: $errorManager.showErrorAlert) {
                
                // Basic OK button to dismiss the alert
                Button("OK", role: .cancel) { }
                
                // Conditionally show a retry button if a retry action exists
                if let retry = errorManager.retryAction {
                    Button("Try Again") {
                        retry()
                    }
                }
            } message: {
                Text(errorManager.errorMessage)
            }
    }
}

/// Convenience extension to apply AR error handling to any SwiftUI view
extension View {
    func withARErrorHandling() -> some View {
        self.modifier(ARErrorAlert())
    }
}

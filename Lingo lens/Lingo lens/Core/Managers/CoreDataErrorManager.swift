//
//  CoreDataErrorManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import Foundation
import SwiftUI

/// A centralized manager for handling CoreData errors throughout the app
/// Captures and displays error alerts when data persistence operations fail
class CoreDataErrorManager: ObservableObject {
    
    // Singleton instance allows global access to error handling
    static let shared = CoreDataErrorManager()
    
    // MARK: - Published Properties

    // Controls visibility of the error alert
    @Published var showErrorAlert = false
    
    // The detailed error message to display to the user
    @Published var errorMessage = ""
    
    // Optional closure that will be executed if the user wants to retry the failed operation
    @Published var retryAction: (() -> Void)? = nil
    
    /// Private initializer enforces singleton pattern and sets up notification observers
    private init() {
        setupNotificationObservers()
    }
    
    // MARK: - Notification Handling

    /// Sets up observers for CoreData error notifications
    /// Listens for both persistent store loading failures and save operation errors
    func setupNotificationObservers() {
        
        // Listen for persistent store loading failures
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CoreDataStoreFailedToLoad"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handlePersistentStoreError(notification)
        }
        
        // Listen for save operation failures
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CoreDataSaveError"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSaveError(notification)
        }
    }
    
    /// Processes persistent store loading errors from notifications
    /// Extracts error details and displays user-friendly message
    private func handlePersistentStoreError(_ notification: Notification) {
        
        // Extract the error details from the notification
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        let errorDescription = error.localizedDescription
        
        // Show error alert with the extracted details
        showError(
            message: "There was a problem accessing saved data: \(errorDescription)",
            retryAction: nil
        )
    }
    
    /// Processes Core Data save operation errors from notifications
    /// Extracts error details and displays user-friendly message
    private func handleSaveError(_ notification: Notification) {
        
        // Extract the error details from the notification
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        let errorDescription = error.localizedDescription
        
        // Show error alert with the extracted details
        showError(
            message: "There was a problem saving your data: \(errorDescription)",
            retryAction: nil
        )
    }
    
    // MARK: - Error Display

    /// Shows an error alert with an optional retry action
    /// - Parameters:
    ///   - message: The error message to display
    ///   - retryAction: Optional closure to execute if user chooses to retry
    func showError(message: String, retryAction: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.retryAction = retryAction
            self?.showErrorAlert = true
        }
    }
}

/// SwiftUI view modifier that adds CoreData error alert functionality to any view
struct CoreDataErrorAlert: ViewModifier {
    
    // Observe the shared error manager to respond to its state changes
    @ObservedObject private var errorManager = CoreDataErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Storage Error", isPresented: $errorManager.showErrorAlert) {
                
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

/// Extension on View to apply the CoreDataErrorAlert modifier
/// Provides a simple way to add CoreData error handling to any view
extension View {
    func withCoreDataErrorHandling() -> some View {
        self.modifier(CoreDataErrorAlert())
    }
}

//
//  CoreDataErrorManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import Foundation
import SwiftUI

/// A centralized manager for handling CoreData errors throughout the app
class CoreDataErrorManager: ObservableObject {
    static let shared = CoreDataErrorManager()
    
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var retryAction: (() -> Void)? = nil
    
    private init() {
        setupNotificationObservers()
    }
    
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CoreDataStoreFailedToLoad"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handlePersistentStoreError(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CoreDataSaveError"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSaveError(notification)
        }
    }
    
    private func handlePersistentStoreError(_ notification: Notification) {
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        let errorDescription = error.localizedDescription
        
        showError(
            message: "There was a problem accessing saved data: \(errorDescription)",
            retryAction: nil
        )
    }
    
    private func handleSaveError(_ notification: Notification) {
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        let errorDescription = error.localizedDescription
        
        showError(
            message: "There was a problem saving your data: \(errorDescription)",
            retryAction: nil
        )
    }
    
    /// Shows an error alert with an optional retry action
    func showError(message: String, retryAction: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.retryAction = retryAction
            self?.showErrorAlert = true
        }
    }
}

/// SwiftUI view modifier to display CoreData errors
struct CoreDataErrorAlert: ViewModifier {
    @ObservedObject private var errorManager = CoreDataErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Storage Error", isPresented: $errorManager.showErrorAlert) {
                Button("OK", role: .cancel) { }
                
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
extension View {
    func withCoreDataErrorHandling() -> some View {
        self.modifier(CoreDataErrorAlert())
    }
}

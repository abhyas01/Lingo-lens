//
//  ARErrorManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import SwiftUI

class ARErrorManager: ObservableObject {
    static let shared = ARErrorManager()
    
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var retryAction: (() -> Void)? = nil
    
    func showError(message: String, retryAction: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.retryAction = retryAction
            self?.showErrorAlert = true
        }
    }
}

struct ARErrorAlert: ViewModifier {
    @ObservedObject private var errorManager = ARErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("AR Detection Error", isPresented: $errorManager.showErrorAlert) {
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

extension View {
    func withARErrorHandling() -> some View {
        self.modifier(ARErrorAlert())
    }
}

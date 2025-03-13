//
//  SpeechErrorManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/13/25.
//

import SwiftUI

class SpeechErrorManager: ObservableObject {
    static let shared = SpeechErrorManager()
    
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

struct SpeechErrorAlert: ViewModifier {
    @ObservedObject private var errorManager = SpeechErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Speech Error", isPresented: $errorManager.showErrorAlert) {
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
    func withSpeechErrorHandling() -> some View {
        self.modifier(SpeechErrorAlert())
    }
}

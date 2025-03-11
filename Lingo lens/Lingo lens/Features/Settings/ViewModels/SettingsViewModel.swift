//
//  SettingsViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

/// Manages state and animations for the expandable settings panel
class SettingsViewModel: ObservableObject {
    
    /// Tracks whether settings panel is expanded from bottom of screen
    @Published var isExpanded = false
    
    // MARK: - Panel Animation

    /// Toggles settings panel with spring animation for smooth expansion/collapse
    func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }
}

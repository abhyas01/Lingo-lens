//
//  SettingsViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

/// Small view model to handle the expandable settings panel in the AR view
/// Controls animation and expansion state of the settings drawer
class SettingsViewModel: ObservableObject {
    
    // Tracks whether the settings panel is currently expanded
    @Published var isExpanded = false
    
    // MARK: - Panel Animation

    /// Toggles the settings panel with a smooth spring animation
    /// Used when user taps the settings button in the AR view
    func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }
}

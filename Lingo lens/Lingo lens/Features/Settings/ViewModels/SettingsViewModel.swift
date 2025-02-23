//
//  SettingsViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var isExpanded = false
    @Published var showLanguageSelection = false
    
    func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }
}

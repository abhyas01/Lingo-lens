//
//  AppearanceManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/12/25.
//

import SwiftUI

class AppearanceManager: ObservableObject {
    enum ColorSchemeOption: Int, CaseIterable, Identifiable {
        case system
        case light
        case dark
        
        var id: Int { self.rawValue }
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "gear"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    @Published var colorSchemeOption: ColorSchemeOption {
        didSet {
            DataManager.shared.saveColorSchemeOption(colorSchemeOption.rawValue)
        }
    }
    
    init() {
        let savedValue = DataManager.shared.getColorSchemeOption()
    
        if let option = ColorSchemeOption(rawValue: savedValue) {
            self.colorSchemeOption = option
        } else {
            self.colorSchemeOption = .system
        }
    }
}

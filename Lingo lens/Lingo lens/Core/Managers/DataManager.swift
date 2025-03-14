//
//  DataManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/13/25.
//

import Foundation
import SwiftUI

/// Singleton manager for handling user defaults data storage across the app
/// Keeps track of user preferences, settings, and states that need to persist between app launches
class DataManager {
    
    // Single shared instance for app-wide access
    static let shared = DataManager()
    
    // Private init stops other parts of app from creating multiple instances
    private init() {}
    
    // MARK: - Keys
    
    // Collection of UserDefaults keys to avoid typos and inconsistencies
    private enum Keys {
        static let selectedLanguageCode = "selectedLanguageCode"
        static let colorSchemeOption = "colorSchemeOption"
        static let neverShowLabelRemovalWarning = "neverShowLabelRemovalWarning"
        static let annotationScale = "annotationScale"
    }
    
    // MARK: - Language Settings
    
    /// Saves the user's selected translation language code
    /// Called when user changes their target language
    func saveSelectedLanguageCode(_ code: String) {
        print("💾 UserDefaults: Saving selected language code: \(code)")
        UserDefaults.standard.set(code, forKey: Keys.selectedLanguageCode)
    }
    
    /// Gets the user's previously selected language code
    /// Returns nil if no language has been selected before
    func getSelectedLanguageCode() -> String? {
        let code = UserDefaults.standard.string(forKey: Keys.selectedLanguageCode)
        if let code = code {
            print("📖 UserDefaults: Retrieved selected language code: \(code)")
        } else {
            print("📖 UserDefaults: No language code found in UserDefaults")
        }
        return code
    }
    
    // MARK: - Appearance Settings
    
    /// Saves the user's chosen app theme (light/dark/system)
    /// Raw integer value from AppearanceManager.ColorSchemeOption
    func saveColorSchemeOption(_ option: Int) {
        print("💾 UserDefaults: Saving color scheme option: \(option)")
        UserDefaults.standard.set(option, forKey: Keys.colorSchemeOption)
    }
    
    /// Gets the user's app theme preference
    /// Returns the raw int value that maps to AppearanceManager.ColorSchemeOption
    func getColorSchemeOption() -> Int {
        let option = UserDefaults.standard.integer(forKey: Keys.colorSchemeOption)
        print("📖 UserDefaults: Retrieved color scheme option: \(option)")
        return option
    }
    
    // MARK: - UI Preferences
    
    /// Saves whether to show the label removal warning
    /// Used to remember "don't show again" preference for alerts
    func saveNeverShowLabelRemovalWarning(_ value: Bool) {
        print("💾 UserDefaults: Saving never show label removal warning: \(value)")
        UserDefaults.standard.set(value, forKey: Keys.neverShowLabelRemovalWarning)
    }
    
    /// Checks if we should hide the label removal warning
    /// Returns true if user selected "don't show again"
    func getNeverShowLabelRemovalWarning() -> Bool {
        let value = UserDefaults.standard.bool(forKey: Keys.neverShowLabelRemovalWarning)
        print("📖 UserDefaults: Retrieved never show label removal warning: \(value)")
        return value
    }
    
    /// Saves the user's preferred annotation size
    /// Scale factor where 1.0 is default size
    func saveAnnotationScale(_ scale: CGFloat) {
        print("💾 UserDefaults: Saving annotation scale: \(scale)")
        UserDefaults.standard.set(Float(scale), forKey: Keys.annotationScale)
    }
    
    /// Gets the saved annotation scale factor
    /// Returns 1.0 (default size) if nothing saved previously
    func getAnnotationScale() -> CGFloat {
        let scale = UserDefaults.standard.float(forKey: Keys.annotationScale)
        let returnScale = scale > 0 ? CGFloat(scale) : 1.0
        print("📖 UserDefaults: Retrieved annotation scale: \(returnScale)" + (scale <= 0 ? " (using default value)" : ""))
        return returnScale
    }
}

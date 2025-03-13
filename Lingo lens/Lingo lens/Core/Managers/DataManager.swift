//
//  DataManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/13/25.
//

import Foundation
import SwiftUI

/// Singleton manager for handling user defaults data storage across the app
class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - Keys
    
    private enum Keys {
        static let selectedLanguageCode = "selectedLanguageCode"
        static let colorSchemeOption = "colorSchemeOption"
        static let neverShowLabelRemovalWarning = "neverShowLabelRemovalWarning"
        static let annotationScale = "annotationScale"
    }
    
    // MARK: - Language Settings
    
    func saveSelectedLanguageCode(_ code: String) {
        UserDefaults.standard.set(code, forKey: Keys.selectedLanguageCode)
    }
    
    func getSelectedLanguageCode() -> String? {
        return UserDefaults.standard.string(forKey: Keys.selectedLanguageCode)
    }
    
    // MARK: - Appearance Settings
    
    func saveColorSchemeOption(_ option: Int) {
        UserDefaults.standard.set(option, forKey: Keys.colorSchemeOption)
    }
    
    func getColorSchemeOption() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.colorSchemeOption)
    }
    
    // MARK: - UI Preferences
    
    func saveNeverShowLabelRemovalWarning(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Keys.neverShowLabelRemovalWarning)
    }
    
    func getNeverShowLabelRemovalWarning() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.neverShowLabelRemovalWarning)
    }
    
    func saveAnnotationScale(_ scale: CGFloat) {
        UserDefaults.standard.set(Float(scale), forKey: Keys.annotationScale)
    }
    
    func getAnnotationScale() -> CGFloat {
        let scale = UserDefaults.standard.float(forKey: Keys.annotationScale)
        return scale > 0 ? CGFloat(scale) : 1.0
    }
}

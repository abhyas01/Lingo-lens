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
        static let launchCount = "launchCount"
        static let isFirstLaunch = "isFirstLaunch"
        static let didFinishOnBoarding = "didFinishOnBoarding"
        static let neverAskForRating = "neverAskForRating"
        static let ratingPromptShown = "ratingPromptShown"
        static let initialLaunchDate = "initialLaunchDate"
        static let didDismissInstructions = "didDismissInstructions"
    }
    
    // MARK: - App Launch Tracking
    
    /// Tracks application launch events and initializes first-time user preferences
    /// - Sets up initial user defaults on first launch including storing the launch date
    /// - Increments the launch counter for returning users
    /// - Should be called during app initialization in the app delegate or scene delegate
    func trackAppLaunch() {
        
        // Initialize user preference for settings bundle
        UserDefaults.standard.register(defaults: [
            "developer_name": "Abhyas Mall"
        ])
        print("Initialized user preference for settings bundle: \(String(describing: UserDefaults.standard.string(forKey: "developer_name")))")
        
        // Check if this is the first launch
        let isFirstLaunch = UserDefaults.standard.object(forKey: Keys.isFirstLaunch) == nil
        
        if isFirstLaunch {
            print("📱 First app launch detected")
            
            // This is the first launch ever
            UserDefaults.standard.set(false, forKey: Keys.isFirstLaunch)
            UserDefaults.standard.set(1, forKey: Keys.launchCount)
            
            // Set initial state for onboarding - false means onboarding hasn't been completed yet
            UserDefaults.standard.set(false, forKey: Keys.didFinishOnBoarding)
            
            // Set initial state for showing instructions - false signifies that user has not yet
            // seen the instructions sheet
            UserDefaults.standard.set(false, forKey: Keys.didDismissInstructions)
            
            // Save the initial launch date
            saveInitialLaunchDate()
            
            // For logging - to check if we successfully wrote the initial launch date
            let _ = getInitialLaunchDate()
            
        } else {
            
            // Increment launch counter
            let currentCount = UserDefaults.standard.integer(forKey: Keys.launchCount)
            UserDefaults.standard.set(currentCount + 1, forKey: Keys.launchCount)
            
            print("📱 App launch #\(currentCount + 1)")
        }
    }
    
    /// Saves the initial launch date to UserDefaults
    /// Called when the app is launched for the first time
    func saveInitialLaunchDate() {
        let currentDate = Date()
        print("💾 UserDefaults: Saving initial launch date: \(currentDate)")
        UserDefaults.standard.set(currentDate, forKey: Keys.initialLaunchDate)
    }

    /// Retrieves the initial launch date from UserDefaults
    /// - Returns: Date when the app was first launched, or nil if not available
    func getInitialLaunchDate() -> Date? {
        guard let date = UserDefaults.standard.object(forKey: Keys.initialLaunchDate) as? Date else {
            print("📖 UserDefaults: No initial launch date found")
            return nil
        }
        print("📖 UserDefaults: Retrieved initial launch date: \(date)")
        return date
    }
    
    /// Checks if this is the first time the app has been launched
    /// - Returns: True if this is the first launch after installation
    func isFirstLaunch() -> Bool {
        let isFirstLaunch = UserDefaults.standard.integer(forKey: Keys.launchCount) <= 1
        print("💾 UserDefaults: First Launch Value: \(isFirstLaunch)")
        return isFirstLaunch
    }
    
    /// Gets the current launch count
    /// - Returns: Number of times the app has been launched
    func getLaunchCount() -> Int {
        let count = UserDefaults.standard.integer(forKey: Keys.launchCount)
        print("📖 UserDefaults: Retrieved launch count: \(count)")
        return count
    }
    
    /// Marks onboarding as complete in UserDefaults
    /// Called when user completes the onboarding process
    func finishOnBoarding() {
        print("💾 UserDefaults: Marking onboarding as finished")
        UserDefaults.standard.set(true, forKey: Keys.didFinishOnBoarding)
    }
    
    /// Checks if user has completed the onboarding process
    /// Returns true if onboarding was completed, false if it still needs to be shown
    func didFinishOnBoarding() -> Bool {
        let finished = UserDefaults.standard.bool(forKey: Keys.didFinishOnBoarding)
        print("📖 UserDefaults: Retrieved onboarding completion status: \(finished)")
        return finished
    }
    
    /// Checks if the user has previously dismissed the instructions screen
    /// Returns true if instructions were dismissed, false if they should be shown
    func hasDismissedInstructions() -> Bool {
        let dismissedState = UserDefaults.standard.bool(forKey: Keys.didDismissInstructions)
        print("📖 UserDefaults: Retrieved instructions dismissal status: \(dismissedState)")
        return dismissedState
    }

    /// Marks instructions as dismissed in UserDefaults
    /// Called when user closes the instructions screen
    func dismissedInstructions() {
        print("💾 UserDefaults: Marking instructions as dismissed")
        UserDefaults.standard.set(true, forKey: Keys.didDismissInstructions)
    }
    
    /// Checks if app should show rating prompt on 3rd launch
    func shouldShowRatingPrompt() -> Bool {
        // If user chose "Don't Ask Again", never show prompt
        if UserDefaults.standard.bool(forKey: Keys.neverAskForRating) {
            print("📖 UserDefaults: Rating prompt disabled by user preference")
            return false
        }
        
        // If prompt has already been shown, don't show again
        if UserDefaults.standard.bool(forKey: Keys.ratingPromptShown) {
            print("📖 UserDefaults: Rating prompt already shown")
            return false
        }
        
        // Show on exactly the 3rd launch
        let shouldShow = getLaunchCount() == 3
        print("📖 UserDefaults: Should show rating prompt: \(shouldShow)")
        return shouldShow
    }
    
    /// Marks that rating prompt has been shown
    func markRatingPromptAsShown() {
        print("💾 UserDefaults: Marking rating prompt as shown")
        UserDefaults.standard.set(true, forKey: Keys.ratingPromptShown)
    }

    /// Sets preference to never show rating prompt again
    func setNeverAskForRating() {
        print("💾 UserDefaults: Setting never ask for rating to true")
        UserDefaults.standard.set(true, forKey: Keys.neverAskForRating)
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

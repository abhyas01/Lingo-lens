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
    }
    
    // MARK: - App Launch Tracking
    
    /// Increments the launch count and handles first launch detection
    /// Should be called during app initialization
    func trackAppLaunch() {
        
        // Check if this is the first launch
        let isFirstLaunch = UserDefaults.standard.object(forKey: Keys.isFirstLaunch) == nil
        
        if isFirstLaunch {
            print("📱 First app launch detected")
            
            // This is the first launch ever
            UserDefaults.standard.set(false, forKey: Keys.isFirstLaunch)
            UserDefaults.standard.set(1, forKey: Keys.launchCount)
            
            // Set initial state for onboarding - false means onboarding hasn't been completed yet
            UserDefaults.standard.set(false, forKey: Keys.didFinishOnBoarding)
        } else {
            
            // Increment launch counter
            let currentCount = UserDefaults.standard.integer(forKey: Keys.launchCount)
            UserDefaults.standard.set(currentCount + 1, forKey: Keys.launchCount)
            
            print("📱 App launch #\(currentCount + 1)")
        }
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

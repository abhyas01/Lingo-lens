//
//  DataManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/13/25.
//  Refactored by Claude Code Review on 11/17/25.
//

import Foundation
import SwiftUI

/// Singleton manager for handling user defaults data storage across the app
/// Uses type-safe property wrappers to prevent key errors and improve maintainability
class DataManager {

    // Single shared instance for app-wide access
    static let shared = DataManager()

    // Private init stops other parts of app from creating multiple instances
    private init() {}

    // MARK: - Type-Safe Properties

    @OptionalUserDefault(key: "selectedLanguageCode")
    var selectedLanguageCode: String?

    @UserDefault(key: "colorSchemeOption", defaultValue: 0)
    var colorSchemeOption: Int

    @UserDefault(key: "neverShowLabelRemovalWarning", defaultValue: false)
    var neverShowLabelRemovalWarning: Bool

    @UserDefault(key: "annotationScale", defaultValue: 1.0)
    var annotationScale: Float

    @UserDefault(key: "launchCount", defaultValue: 0)
    var launchCount: Int

    @UserDefault(key: "isFirstLaunch", defaultValue: true)
    var isFirstLaunch: Bool

    @UserDefault(key: "didFinishOnBoarding", defaultValue: false)
    var didFinishOnBoarding: Bool

    @UserDefault(key: "neverAskForRating", defaultValue: false)
    var neverAskForRating: Bool

    @UserDefault(key: "ratingPromptShown", defaultValue: false)
    var ratingPromptShown: Bool

    @OptionalUserDefault(key: "initialLaunchDate")
    var initialLaunchDate: Date?

    @UserDefault(key: "didDismissInstructions", defaultValue: false)
    var didDismissInstructions: Bool
    
    // MARK: - App Launch Tracking

    /// Tracks application launch events and initializes first-time user preferences
    /// - Sets up initial user defaults on first launch including storing the launch date
    /// - Increments the launch counter for returning users
    /// - Should be called during app initialization
    func trackAppLaunch() {
        // Initialize user preference for settings bundle
        UserDefaults.standard.register(defaults: [
            "developer_name": "Abhyas Mall"
        ])
        Logger.info("Initialized settings bundle preferences")

        // Check if this is truly the first launch (property has never been set)
        if UserDefaults.standard.object(forKey: "isFirstLaunch") == nil {
            Logger.info("First app launch detected")

            // Set up initial values
            isFirstLaunch = false
            launchCount = 1
            didFinishOnBoarding = false
            didDismissInstructions = false
            initialLaunchDate = Date()
        } else {
            // Increment launch counter
            launchCount += 1
            Logger.info("App launch #\(launchCount)")
        }
    }

    /// Marks onboarding as complete
    func finishOnBoarding() {
        didFinishOnBoarding = true
    }

    /// Marks instructions as dismissed
    func dismissInstructions() {
        didDismissInstructions = true
    }

    /// Checks if app should show rating prompt on 3rd launch
    func shouldShowRatingPrompt() -> Bool {
        guard !neverAskForRating else {
            Logger.debug("Rating prompt disabled by user preference")
            return false
        }

        guard !ratingPromptShown else {
            Logger.debug("Rating prompt already shown")
            return false
        }

        let shouldShow = launchCount == AppLaunchConstants.ratingPromptLaunchCount
        Logger.debug("Should show rating prompt: \(shouldShow)")
        return shouldShow
    }

    /// Marks that rating prompt has been shown
    func markRatingPromptAsShown() {
        ratingPromptShown = true
    }

    /// Sets preference to never show rating prompt again
    func setNeverAskForRating() {
        neverAskForRating = true
    }
    
    // MARK: - Language Settings

    /// Saves the user's selected translation language code
    func saveSelectedLanguageCode(_ code: String) {
        selectedLanguageCode = code
    }

    /// Gets the user's previously selected language code
    func getSelectedLanguageCode() -> String? {
        return selectedLanguageCode
    }

    // MARK: - Appearance Settings

    /// Saves the user's chosen app theme (light/dark/system)
    func saveColorSchemeOption(_ option: Int) {
        colorSchemeOption = option
    }

    /// Gets the user's app theme preference
    func getColorSchemeOption() -> Int {
        return colorSchemeOption
    }

    // MARK: - UI Preferences

    /// Saves whether to show the label removal warning
    func saveNeverShowLabelRemovalWarning(_ value: Bool) {
        neverShowLabelRemovalWarning = value
    }

    /// Checks if we should hide the label removal warning
    func getNeverShowLabelRemovalWarning() -> Bool {
        return neverShowLabelRemovalWarning
    }

    /// Saves the user's preferred annotation size
    func saveAnnotationScale(_ scale: CGFloat) {
        annotationScale = Float(scale)
    }

    /// Gets the saved annotation scale factor (returns 1.0 as default)
    func getAnnotationScale() -> CGFloat {
        return annotationScale > 0 ? CGFloat(annotationScale) : 1.0
    }

    /// Checks if user has dismissed instructions
    func hasDismissedInstructions() -> Bool {
        return didDismissInstructions
    }
}

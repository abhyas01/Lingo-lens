//
//  HapticManager.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import UIKit

/// Centralized haptic feedback manager
/// Provides consistent haptic responses throughout the app
class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Generators

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Prepare generators for faster response
        prepareAll()
    }

    // MARK: - Public Methods

    /// Light impact - for subtle interactions (button hover, small toggles)
    func light() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium impact - for standard interactions (button taps, confirmations)
    func medium() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Heavy impact - for important actions (deletion, major changes)
    func heavy() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    /// Selection feedback - for picker changes, segmented control
    func selection() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    /// Success notification - for successful operations (translation complete, save successful)
    func success() {
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    /// Warning notification - for warnings (language not downloaded, low confidence)
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }

    /// Error notification - for errors (translation failed, placement failed)
    func error() {
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }

    // MARK: - Private Methods

    private func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
}

// MARK: - Convenience Extensions

extension HapticManager {

    /// Haptic for button tap
    func buttonTap() {
        medium()
    }

    /// Haptic for toggle switch
    func toggle() {
        selection()
    }

    /// Haptic for mode change
    func modeChange() {
        medium()
    }

    /// Haptic for translation success
    func translationSuccess() {
        success()
    }

    /// Haptic for speaker change
    func speakerChange() {
        light()
    }

    /// Haptic for annotation placement
    func annotationPlaced() {
        success()
    }

    /// Haptic for annotation removal
    func annotationRemoved() {
        heavy()
    }

    /// Haptic for copy action
    func copied() {
        light()
    }

    /// Haptic for language download complete
    func downloadComplete() {
        success()
    }
}

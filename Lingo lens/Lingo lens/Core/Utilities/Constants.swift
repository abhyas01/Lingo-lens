//
//  Constants.swift
//  Lingo lens
//
//  Created by Claude Code Review on 11/17/25.
//

import Foundation
import CoreGraphics

// MARK: - AR Constants

enum ARConstants {
    // Raycasting
    static let defaultRaycastDistance: Float = 0.5  // 0.5 meters from camera

    // Text Overlays
    static let textOverlayPlaneHeight: CGFloat = 0.05  // 5cm height
    static let textOverlayPadding: CGFloat = 20
    static let textOverlayCornerRadiusRatio: CGFloat = 0.3
    static let textOverlayBackgroundAlpha: CGFloat = 0.85
    static let textOverlayEmissionAlpha: CGFloat = 0.2

    // Font Sizing
    static let baseFontSize: CGFloat = 200
    static let minFontSizeScale: CGFloat = 0.5
    static let maxFontSizeScale: CGFloat = 3.0
    static let fontSizeHeightDivisor: CGFloat = 20.0

    // Annotation Dimensions
    static let annotationBaseWidth: CGFloat = 0.18  // 18cm
    static let annotationExtraWidthPerChar: CGFloat = 0.005  // 0.5cm per character
    static let annotationMaxWidth: CGFloat = 0.40  // 40cm maximum
    static let annotationMinWidth: CGFloat = 0.18  // 18cm minimum
    static let annotationHeight: CGFloat = 0.09  // 9cm
    static let annotationCornerRadius: CGFloat = 0.015  // 1.5cm
    static let annotationVerticalOffset: CGFloat = 0.04  // 4cm above anchor

    // Timing
    static let annotationAddDelay: TimeInterval = 0.5
    static let annotationDeleteDelay: TimeInterval = 0.5
    static let placementErrorDuration: TimeInterval = 4.0
    static let sessionResumeDelay: TimeInterval = 0.5
    static let sessionTransitionDuration: TimeInterval = 0.3
}

// MARK: - Text Processing Constants

enum TextProcessingConstants {
    static let maxCharsPerLine: Int = 20
    static let maxLines: Int = 2
    static let ellipsis: String = "..."
}

// MARK: - SpriteKit Scene Constants

enum SpriteKitConstants {
    static let annotationSceneWidth: CGFloat = 400
    static let annotationSceneHeight: CGFloat = 140
    static let capsuleCornerRadius: CGFloat = 50
    static let chevronFontSize: CGFloat = 36
    static let labelFontSize: CGFloat = 32
    static let lineHeight: CGFloat = 40
    static let chevronXOffset: CGFloat = 40
}

// MARK: - Detection Constants

enum DetectionConstants {
    static let minimumConfidence: Float = 0.5
    static let insideMargin: CGFloat = 4
    static let minimumCropDimension: CGFloat = 10
}

// MARK: - Translation Constants

enum TranslationConstants {
    static let maxCharacterLimit: Int = 5000
    static let maxHistoryItems: Int = 20
    static let debounceIntervalMs: Int = 500
}

// MARK: - Conversation Constants

enum ConversationConstants {
    static let maxMessages: Int = 100
    static let minAudioLevel: Float = 0.0
    static let maxAudioLevel: Float = 1.0
}

// MARK: - App Launch Constants

enum AppLaunchConstants {
    static let ratingPromptLaunchCount: Int = 3
    static let splashScreenDuration: TimeInterval = 0.7
}

// MARK: - Speech Constants

enum SpeechConstants {
    static let defaultSpeechRateMultiplier: Float = 0.9
    static let defaultPitchMultiplier: Float = 1.0
    static let defaultVolume: Float = 1.0
}

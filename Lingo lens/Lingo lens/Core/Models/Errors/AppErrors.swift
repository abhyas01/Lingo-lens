//
//  AppErrors.swift
//  Lingo lens
//
//  Created by Claude Code Review on 11/17/25.
//

import Foundation

// MARK: - Translation Errors

/// Errors that can occur during translation operations
enum TranslationError: LocalizedError {
    case networkUnavailable
    case languageNotDownloaded(String)
    case invalidInput
    case serviceUnavailable
    case sessionFailed(Error)
    case unsupportedLanguagePair(source: String, target: String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .languageNotDownloaded(let language):
            return "The '\(language)' language pack needs to be downloaded for offline use."
        case .invalidInput:
            return "The text contains invalid characters or is too long."
        case .serviceUnavailable:
            return "Translation service is temporarily unavailable. Please try again later."
        case .sessionFailed(let error):
            return "Translation failed: \(error.localizedDescription)"
        case .unsupportedLanguagePair(let source, let target):
            return "Translation from '\(source)' to '\(target)' is not supported."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Connect to Wi-Fi or cellular data and try again."
        case .languageNotDownloaded:
            return "Download the language pack in Settings > Translation."
        case .invalidInput:
            return "Check your text for special characters or reduce its length."
        case .serviceUnavailable:
            return "Wait a moment and try again."
        case .sessionFailed:
            return "Try restarting the app or check your internet connection."
        case .unsupportedLanguagePair:
            return "Choose a different language combination."
        }
    }
}

// MARK: - AR Errors

/// Errors that can occur during AR operations
enum ARError: LocalizedError {
    case modelLoadFailed(String)
    case sessionNotReady
    case trackingLimited
    case cameraAccessDenied
    case unsupportedDevice
    case detectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let modelName):
            return "Failed to load \(modelName) model."
        case .sessionNotReady:
            return "AR session is not ready. Please wait."
        case .trackingLimited:
            return "AR tracking quality is limited."
        case .cameraAccessDenied:
            return "Camera access is required for AR features."
        case .unsupportedDevice:
            return "This device doesn't support AR features."
        case .detectionFailed(let reason):
            return "Object detection failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .modelLoadFailed:
            return "Try restarting the app. If the problem persists, reinstall the app."
        case .sessionNotReady:
            return "Wait a moment for AR to initialize."
        case .trackingLimited:
            return "Move to a well-lit area with visible features."
        case .cameraAccessDenied:
            return "Enable camera access in Settings > Privacy > Camera."
        case .unsupportedDevice:
            return "This feature requires an iPhone with AR capabilities."
        case .detectionFailed:
            return "Try pointing at a clearer object or improving lighting."
        }
    }
}

// MARK: - Speech Errors

/// Errors that can occur during speech operations
enum SpeechError: LocalizedError {
    case microphoneAccessDenied
    case recognitionNotAvailable
    case audioSessionFailed(Error)
    case noVoiceAvailable(String)
    case recognitionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access is required for speech features."
        case .recognitionNotAvailable:
            return "Speech recognition is not available on this device."
        case .audioSessionFailed(let error):
            return "Audio session error: \(error.localizedDescription)"
        case .noVoiceAvailable(let language):
            return "No voice available for '\(language)'."
        case .recognitionFailed(let error):
            return "Speech recognition failed: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Enable microphone access in Settings > Privacy > Microphone."
        case .recognitionNotAvailable:
            return "Speech recognition may require an internet connection."
        case .audioSessionFailed:
            return "Close other apps using audio and try again."
        case .noVoiceAvailable:
            return "Download additional voices in Settings > Accessibility > Spoken Content."
        case .recognitionFailed:
            return "Speak clearly and ensure you're in a quiet environment."
        }
    }
}

// MARK: - CoreData Errors

/// Errors that can occur during data persistence operations
enum PersistenceError: LocalizedError {
    case storeLoadFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case migrationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .storeLoadFailed(let error):
            return "Failed to load data store: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Failed to migrate data: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .storeLoadFailed:
            return "Your data may be corrupted. You may need to reinstall the app."
        case .saveFailed:
            return "Check available storage space and try again."
        case .fetchFailed:
            return "Try restarting the app."
        case .deleteFailed:
            return "Try again or restart the app."
        case .migrationFailed:
            return "App data needs to be reset. You may lose saved translations."
        }
    }
}

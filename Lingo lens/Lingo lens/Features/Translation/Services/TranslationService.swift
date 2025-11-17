//
//  TranslationService.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import Foundation
import Translation
import SwiftUI

/// Manages language selection, availability, and translation requests
/// Acts as the central coordinator for all translation features
class TranslationService: ObservableObject {
    
    // Currently translated text from latest translation request
    @Published var translatedText = ""
    
    // List of languages supported by the iOS translation system
    @Published var availableLanguages: [AvailableLanguage] = []
    
    // Tracks if we're still loading the initial language list
    @Published var isInitialLoading = true
    
    // Fixed source language (English) for all translations
    let sourceLanguage = Locale.Language(languageCode: "en")
    
    // MARK: - Setup

    init() {
        // Start loading languages when service is created
        Task {
            await getSupportedLanguages()
        }
    }
    
    // MARK: - Language Management

    
    /// Checks if a specific language has been downloaded for offline use
    /// - Parameter language: The language to check
    /// - Returns: True if language is downloaded, false otherwise
    func isLanguageDownloaded(language: AvailableLanguage) async -> Bool {
        Logger.debug("Checking if language is downloaded: \(language.shortName())")
        let availability = LanguageAvailability()
        let status = await availability.status(
            from: sourceLanguage,
            to: language.locale
        )

        // Check the download status from the system
        switch status {
        case .installed:
            Logger.debug("Language \(language.shortName()) is installed")
            return true

        case .supported, .unsupported:
            Logger.debug("Language \(language.shortName()) is not installed")
            return false

        @unknown default:
            Logger.warning("Unknown language availability status")
            return false
        }
    }
    
    /// Fetches available languages from iOS translation system
    /// Populates the availableLanguages array with all supported translation languages
    @MainActor
    func getSupportedLanguages() async {
        Logger.info("Loading supported languages...")
        isInitialLoading = true

        // Get all languages supported by the device
        let supportedLanguages = await LanguageAvailability().supportedLanguages
        Logger.info("Found \(supportedLanguages.count) supported languages")

        // Filter out English (since it's our source language)
        // and create our own AvailableLanguage objects
        availableLanguages = supportedLanguages
            .filter { $0.languageCode != "en" }
            .map { AvailableLanguage(locale: $0) }
            .sorted()

        Logger.info("Filtered to \(availableLanguages.count) available languages (excluding English)")
        isInitialLoading = false
    }
    
    // MARK: - Translation

    /// Performs translation using iOS system services
    /// - Parameters:
    ///   - text: The text to translate
    ///   - session: Active translation session for the target language
    @MainActor
    func translate(text: String, using session: TranslationSession) async throws {
        Logger.debug("Translating text: \"\(text)\"")

        do {
            // Use the Apple Translation framework to translate the text
            let response = try await session.translate(text)

            Logger.debug("Translation result: \"\(response.targetText)\"")
            // Update our published property with the result
            translatedText = response.targetText
        } catch {
            Logger.error("Translation failed: \(error.localizedDescription)")
            throw TranslationError.sessionFailed(error)
        }
    }
}

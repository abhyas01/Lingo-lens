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
class TranslationService: ObservableObject {
    
    /// Currently translated text from latest translation request
    @Published var translatedText = ""
    
    /// List of languages supported by the iOS translation system
    @Published var availableLanguages: [AvailableLanguage] = []
    
    @Published var isInitialLoading = true
    
    /// Fixed source language (English) for all translations
    let sourceLanguage = Locale.Language(languageCode: "en")
    
    // MARK: - Setup

    init() {
        getSupportedLanguages()
    }
    
    // MARK: - Language Management

    func isLanguageDownloaded(language: AvailableLanguage) async -> Bool {
        let availability = LanguageAvailability()
        let status = await availability.status(
            from: sourceLanguage,
            to: language.locale
        )
        
        switch status {
        case .installed:
            return true
        case .supported, .unsupported:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Fetches available languages from iOS translation system
    func getSupportedLanguages() {
        isInitialLoading = true
        
        Task { @MainActor in
            let supportedLanguages = await LanguageAvailability().supportedLanguages
            availableLanguages = supportedLanguages
                .filter { $0.languageCode != "en" }
                .map { AvailableLanguage(locale: $0) }
                .sorted()
            isInitialLoading = false
        }
    }
    
    // MARK: - Translation

    /// Performs translation using iOS system services
    @MainActor
    func translate(text: String, using session: TranslationSession) async throws {
        let response = try await session.translate(text)
        translatedText = response.targetText
    }
}

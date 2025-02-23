//
//  TranslationService.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import Foundation
import Translation

class TranslationService: ObservableObject {
    @Published var translatedText = ""
    @Published var availableLanguages: [AvailableLanguage] = []
    
    // Add a property for the source language (English)
    let sourceLanguage = Locale.Language(languageCode: "en")
    
    init() {
        getSupportedLanguages()
    }
    
    func getSupportedLanguages() {
        Task { @MainActor in
            let supportedLanguages = await LanguageAvailability().supportedLanguages
            availableLanguages = supportedLanguages
                .filter { $0.languageCode != "en" }
                .map { AvailableLanguage(locale: $0) }
                .sorted()
        }
    }
    
    @MainActor
    func translate(text: String, using session: TranslationSession) async throws {
        let response = try await session.translate(text)
        translatedText = response.targetText
    }
}

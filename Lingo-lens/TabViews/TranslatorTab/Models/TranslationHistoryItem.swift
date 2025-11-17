//
//  TranslationHistoryItem.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation

/// Represents a translation in the session history
struct TranslationHistoryItem: Identifiable, Codable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let sourceLanguage: String  // Language identifier
    let targetLanguage: String  // Language identifier
    let timestamp: Date

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.timestamp = timestamp
    }

    /// Returns the source language display name
    var sourceLanguageName: String {
        Locale.current.localizedString(forIdentifier: sourceLanguage) ?? sourceLanguage
    }

    /// Returns the target language display name
    var targetLanguageName: String {
        Locale.current.localizedString(forIdentifier: targetLanguage) ?? targetLanguage
    }

    /// Returns a formatted timestamp
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

//
//  LanguageDetectionManager.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation
import NaturalLanguage

/// Manages automatic language detection for text input
class LanguageDetectionManager {

    // MARK: - Properties

    private let recognizer = NLLanguageRecognizer()

    // MARK: - Public Methods

    /// Detects the dominant language in the given text
    /// - Parameter text: The text to analyze
    /// - Returns: The detected language as a Locale.Language, or nil if detection fails
    func detectLanguage(text: String) -> Locale.Language? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        recognizer.reset()
        recognizer.processString(text)

        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return nil
        }

        // Convert NLLanguage to Locale.Language
        return Locale.Language(identifier: languageCode)
    }

    /// Gets confidence scores for top language hypotheses
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - maxResults: Maximum number of hypotheses to return (default 3)
    /// - Returns: Dictionary mapping languages to their confidence scores (0.0 to 1.0)
    func getLanguageHypotheses(for text: String, maxResults: Int = 3) -> [(language: Locale.Language, confidence: Double)] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        recognizer.reset()
        recognizer.processString(text)

        let hypotheses = recognizer.languageHypotheses(withMaximum: maxResults)

        return hypotheses.map { (language, confidence) in
            (language: Locale.Language(identifier: language.rawValue), confidence: confidence)
        }.sorted { $0.confidence > $1.confidence }
    }

    /// Checks if the text is likely in the specified language
    /// - Parameters:
    ///   - text: The text to check
    ///   - language: The language to check against
    ///   - confidenceThreshold: Minimum confidence required (default 0.5)
    /// - Returns: True if the text is likely in the specified language
    func isText(_ text: String, inLanguage language: Locale.Language, confidenceThreshold: Double = 0.5) -> Bool {
        guard let detected = detectLanguage(text: text) else {
            return false
        }

        let hypotheses = getLanguageHypotheses(for: text, maxResults: 1)
        guard let topHypothesis = hypotheses.first else {
            return false
        }

        return detected.minimalIdentifier == language.minimalIdentifier &&
               topHypothesis.confidence >= confidenceThreshold
    }

    /// Detects if text contains multiple languages
    /// - Parameter text: The text to analyze
    /// - Returns: Array of detected languages with their confidence scores
    func detectMultipleLanguages(in text: String) -> [(language: Locale.Language, confidence: Double)] {
        return getLanguageHypotheses(for: text, maxResults: 5)
            .filter { $0.confidence > 0.3 }
    }
}

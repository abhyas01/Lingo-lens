//
//  ConversationMessage.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation

/// Represents a message in a conversation with translation
struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let speaker: Speaker
    let timestamp: Date
    let confidence: Float

    enum Speaker: String, Codable {
        case me
        case them

        var displayName: String {
            switch self {
            case .me: return "Me"
            case .them: return "Them"
            }
        }
    }

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        speaker: Speaker,
        timestamp: Date = Date(),
        confidence: Float = 1.0
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.speaker = speaker
        self.timestamp = timestamp
        self.confidence = confidence
    }

    /// Formatted timestamp for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Source language display name
    var sourceLanguageName: String {
        Locale.current.localizedString(forIdentifier: sourceLanguage) ?? sourceLanguage
    }

    /// Target language display name
    var targetLanguageName: String {
        Locale.current.localizedString(forIdentifier: targetLanguage) ?? targetLanguage
    }
}

// MARK: - Conversation Export

extension Array where Element == ConversationMessage {
    /// Exports conversation to plain text format
    func exportToText() -> String {
        var output = "Conversation Export\n"
        output += "Generated: \(Date().formatted())\n"
        output += String(repeating: "=", count: 50) + "\n\n"

        for message in self {
            output += "[\(message.formattedTime)] \(message.speaker.displayName)\n"
            output += "  Original (\(message.sourceLanguageName)): \(message.originalText)\n"
            output += "  Translation (\(message.targetLanguageName)): \(message.translatedText)\n\n"
        }

        return output
    }

    /// Exports conversation to JSON format
    func exportToJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }
}

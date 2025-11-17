//
//  ConversationBubble.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Chat bubble view for conversation messages
struct ConversationBubble: View {

    let message: ConversationMessage

    var body: some View {
        HStack {
            if message.speaker == .me {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.speaker == .me ? .trailing : .leading, spacing: 8) {
                // Original text
                VStack(alignment: message.speaker == .me ? .trailing : .leading, spacing: 4) {
                    Text(message.originalText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                            .font(.caption2)
                        Text(message.sourceLanguageName)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(message.speaker == .me ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.speaker == .me ? .white : .primary)
                .cornerRadius(18)

                // Translation
                VStack(alignment: message.speaker == .me ? .trailing : .leading, spacing: 4) {
                    Text(message.translatedText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text(message.targetLanguageName)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Timestamp
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.speaker == .them {
                Spacer(minLength: 50)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConversationBubble(
            message: ConversationMessage(
                originalText: "Hello, how are you?",
                translatedText: "Hola, ¿cómo estás?",
                sourceLanguage: "en",
                targetLanguage: "es",
                speaker: .me
            )
        )

        ConversationBubble(
            message: ConversationMessage(
                originalText: "Muy bien, gracias",
                translatedText: "Very well, thank you",
                sourceLanguage: "es",
                targetLanguage: "en",
                speaker: .them
            )
        )
    }
    .padding()
}

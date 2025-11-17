//
//  TranslationHistoryRow.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Row view for translation history items
struct TranslationHistoryRow: View {

    let item: TranslationHistoryItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Language indicator
            VStack(spacing: 4) {
                Text(languageCode(from: item.sourceLanguage))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(languageCode(from: item.targetLanguage))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 32)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.originalText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.translatedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Timestamp
            Text(item.formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func languageCode(from identifier: String) -> String {
        // Extract first 2 characters of language code
        String(identifier.prefix(2)).uppercased()
    }
}

#Preview {
    TranslationHistoryRow(
        item: TranslationHistoryItem(
            originalText: "Hello, how are you?",
            translatedText: "Hola, ¿cómo estás?",
            sourceLanguage: "en",
            targetLanguage: "es"
        )
    )
    .padding()
}

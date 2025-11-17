//
//  TranslationOutputCard.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Card component for displaying translation results
struct TranslationOutputCard: View {

    let translatedText: String
    let isTranslating: Bool
    let onListen: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    @State private var showCopiedConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Translation")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                if isTranslating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Translation text
            if isTranslating {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                ScrollView {
                    Text(translatedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 100, maxHeight: 200)
            }

            // Action buttons
            if !isTranslating && !translatedText.isEmpty {
                Divider()

                HStack(spacing: 16) {
                    actionButton(icon: "speaker.wave.2", title: "Listen", action: onListen)
                    actionButton(icon: showCopiedConfirmation ? "checkmark" : "doc.on.doc", title: "Copy", action: copyAction)
                    actionButton(icon: "star", title: "Save", action: onSave)
                    actionButton(icon: "square.and.arrow.up", title: "Share", action: onShare)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }

    private func copyAction() {
        onCopy()
        showCopiedConfirmation = true

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedConfirmation = false
        }
    }
}

#Preview {
    TranslationOutputCard(
        translatedText: "Hola, mundo!",
        isTranslating: false,
        onListen: {},
        onCopy: {},
        onSave: {},
        onShare: {}
    )
    .padding()
}

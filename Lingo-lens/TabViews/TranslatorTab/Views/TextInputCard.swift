//
//  TextInputCard.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Card component for text input with character counter
struct TextInputCard: View {

    @Binding var text: String
    let placeholder: String
    let characterCount: Int
    let maxCharacters: Int
    let isOverLimit: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: 150, maxHeight: 300)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )

            // Bottom toolbar
            HStack {
                // Character counter
                Text("\(characterCount)/\(maxCharacters)")
                    .font(.caption)
                    .foregroundColor(isOverLimit ? .red : .secondary)

                Spacer()

                // Paste button
                Button(action: pasteFromClipboard) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(text.count >= maxCharacters)

                // Clear button
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func pasteFromClipboard() {
        #if os(iOS)
        if let clipboardText = UIPasteboard.general.string {
            let availableSpace = maxCharacters - text.count
            if availableSpace > 0 {
                let textToAdd = String(clipboardText.prefix(availableSpace))
                text += textToAdd
            }
        }
        #endif
    }
}

#Preview {
    TextInputCard(
        text: .constant("Hello, world!"),
        placeholder: "Enter text",
        characterCount: 13,
        maxCharacters: 5000,
        isOverLimit: false
    )
    .padding()
}

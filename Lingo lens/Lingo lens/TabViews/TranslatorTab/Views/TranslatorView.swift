//
//  TranslatorView.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Main view for the text translator tab
struct TranslatorView: View {

    @StateObject private var viewModel: TranslatorViewModel
    @EnvironmentObject var translationService: TranslationService
    @State private var showShareSheet = false

    init(translationService: TranslationService) {
        _viewModel = StateObject(wrappedValue: TranslatorViewModel(translationService: translationService))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Language selector section
                    languageSelectionSection

                    // Input text card
                    TextInputCard(
                        text: $viewModel.inputText,
                        placeholder: "Enter text to translate",
                        characterCount: viewModel.characterCount,
                        maxCharacters: 5000,
                        isOverLimit: viewModel.isOverLimit
                    )

                    // Translation output card
                    if !viewModel.translatedText.isEmpty || viewModel.isTranslating {
                        TranslationOutputCard(
                            translatedText: viewModel.translatedText,
                            isTranslating: viewModel.isTranslating,
                            onListen: {
                                viewModel.playTranslation()
                            },
                            onCopy: {
                                viewModel.copyTranslation()
                            },
                            onSave: {
                                viewModel.saveTranslation()
                            },
                            onShare: {
                                showShareSheet = true
                            }
                        )
                    }

                    // Detected language indicator
                    if viewModel.isAutoDetect, let detected = viewModel.detectedLanguage {
                        detectedLanguageView(detected)
                    }

                    // Translation history
                    if !viewModel.translationHistory.isEmpty {
                        translationHistorySection
                    }
                }
                .padding()
            }
            .navigationTitle("Translator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.clearText) {
                            Label("Clear Text", systemImage: "trash")
                        }
                        Button(action: viewModel.clearHistory) {
                            Label("Clear History", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !viewModel.translatedText.isEmpty {
                    ShareSheet(items: [viewModel.translatedText])
                }
            }
        }
    }

    // MARK: - Subviews

    private var languageSelectionSection: some View {
        HStack(spacing: 12) {
            // Source language picker
            LanguageSelectorView(
                selectedLanguage: $viewModel.sourceLanguage,
                allowAutoDetect: true,
                title: "From"
            )

            // Swap button
            Button(action: viewModel.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .disabled(viewModel.isAutoDetect)

            // Target language picker
            LanguageSelectorView(
                selectedLanguage: Binding(
                    get: { viewModel.targetLanguage },
                    set: { viewModel.targetLanguage = $0 ?? .spanish }
                ),
                allowAutoDetect: false,
                title: "To"
            )
        }
    }

    private func detectedLanguageView(_ language: Locale.Language) -> some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.blue)
            Text("Detected: \(language.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var translationHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Translations")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Clear") {
                    viewModel.clearHistory()
                }
                .font(.caption)
            }

            ForEach(viewModel.translationHistory.prefix(5)) { item in
                TranslationHistoryRow(item: item)
                    .onTapGesture {
                        viewModel.loadFromHistory(item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteHistoryItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    TranslatorView(translationService: TranslationService())
        .environmentObject(TranslationService())
}

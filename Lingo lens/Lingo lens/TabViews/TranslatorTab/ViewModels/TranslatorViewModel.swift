//
//  TranslatorViewModel.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation
import Translation
import Combine

/// Manages state and logic for the Translator tab
@MainActor
class TranslatorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var sourceLanguage: Locale.Language? = nil  // nil = auto-detect
    @Published var targetLanguage: Locale.Language = .spanish
    @Published var inputText: String = ""
    @Published var translatedText: String = ""
    @Published var detectedLanguage: Locale.Language?
    @Published var isTranslating: Bool = false
    @Published var translationHistory: [TranslationHistoryItem] = []
    @Published var showLanguageDownload: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let translationService: TranslationService
    private let languageDetectionManager = LanguageDetectionManager()
    private let speechRecognitionManager = SpeechRecognitionManager()
    private var debounceTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Constants
    private let maxCharacterLimit = 5000
    private let maxHistoryItems = 20
    private let debounceIntervalMs = 500

    // MARK: - Computed Properties

    var characterCount: Int {
        inputText.count
    }

    var isOverLimit: Bool {
        characterCount > maxCharacterLimit
    }

    var canTranslate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isOverLimit &&
        !isTranslating
    }

    var isAutoDetect: Bool {
        sourceLanguage == nil
    }

    // MARK: - Initialization

    init(translationService: TranslationService = TranslationService()) {
        self.translationService = translationService

        // Set up text change observation
        setupTextObservation()
    }

    // MARK: - Public Methods

    /// Performs translation with current settings
    func translate() async {
        guard canTranslate else { return }

        isTranslating = true
        errorMessage = nil

        do {
            // Detect language if auto-detect is enabled
            let sourceLang: Locale.Language
            if let specifiedLanguage = sourceLanguage {
                sourceLang = specifiedLanguage
            } else {
                // Auto-detect
                if let detected = languageDetectionManager.detectLanguage(text: inputText) {
                    detectedLanguage = detected
                    sourceLang = detected
                } else {
                    // Fallback to English if detection fails
                    detectedLanguage = .english
                    sourceLang = .english
                }
            }

            // Check if translation is needed
            if sourceLang.minimalIdentifier == targetLanguage.minimalIdentifier {
                translatedText = inputText
                isTranslating = false
                return
            }

            // Check if language is available
            let availability = await translationService.checkLanguageAvailability(
                source: sourceLang,
                target: targetLanguage
            )

            if availability == .needsDownload {
                showLanguageDownload = true
                isTranslating = false
                return
            }

            // Perform translation
            let configuration = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLang.minimalIdentifier),
                target: Locale.Language(identifier: targetLanguage.minimalIdentifier)
            )

            let session = TranslationSession(configuration: configuration)

            let response = try await session.translate(inputText)
            translatedText = response.targetText

            // Haptic feedback for successful translation
            HapticManager.shared.translationSuccess()

            // Add to history
            addToHistory(
                original: inputText,
                translation: translatedText,
                source: sourceLang.minimalIdentifier,
                target: targetLanguage.minimalIdentifier
            )

        } catch {
            errorMessage = "Translation Failed:\n• Check your connection\n• Download language for offline\n• Verify text is valid"
            translatedText = ""

            // Haptic feedback for error
            HapticManager.shared.error()
        }

        isTranslating = false
    }

    /// Swaps source and target languages
    func swapLanguages() {
        // Can't swap if auto-detect is enabled
        guard let source = sourceLanguage else { return }

        // Haptic feedback for swap
        HapticManager.shared.selection()

        let temp = source
        sourceLanguage = targetLanguage
        targetLanguage = temp

        // Swap texts too
        let tempText = inputText
        inputText = translatedText
        translatedText = tempText

        // Trigger translation if there's text
        if !inputText.isEmpty {
            Task {
                await translate()
            }
        }
    }

    /// Clears all text
    func clearText() {
        inputText = ""
        translatedText = ""
        detectedLanguage = nil
        errorMessage = nil
    }

    /// Copies translation to clipboard
    func copyTranslation() {
        #if os(iOS)
        UIPasteboard.general.string = translatedText
        HapticManager.shared.copied()
        #endif
    }

    /// Loads a history item back into the translator
    func loadFromHistory(_ item: TranslationHistoryItem) {
        inputText = item.originalText
        sourceLanguage = Locale.Language(identifier: item.sourceLanguage)
        targetLanguage = Locale.Language(identifier: item.targetLanguage)
        translatedText = item.translatedText
    }

    /// Deletes a history item
    func deleteHistoryItem(_ item: TranslationHistoryItem) {
        translationHistory.removeAll { $0.id == item.id }
    }

    /// Clears all history
    func clearHistory() {
        translationHistory.removeAll()
    }

    // MARK: - Private Methods

    private func setupTextObservation() {
        $inputText
            .debounce(for: .milliseconds(debounceIntervalMs), scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self = self, !text.isEmpty else { return }
                Task {
                    await self.translate()
                }
            }
            .store(in: &cancellables)
    }

    private func addToHistory(original: String, translation: String, source: String, target: String) {
        // Don't add empty translations
        guard !original.isEmpty, !translation.isEmpty else { return }

        // Don't add duplicates (check last item)
        if let last = translationHistory.first,
           last.originalText == original &&
           last.translatedText == translation {
            return
        }

        let item = TranslationHistoryItem(
            originalText: original,
            translatedText: translation,
            sourceLanguage: source,
            targetLanguage: target
        )

        // Add to beginning of array
        translationHistory.insert(item, at: 0)

        // Limit history size
        if translationHistory.count > maxHistoryItems {
            translationHistory = Array(translationHistory.prefix(maxHistoryItems))
        }
    }
}

// MARK: - Language Availability Extension

extension TranslationService {
    enum LanguageAvailability {
        case available
        case needsDownload
        case unsupported
    }

    func checkLanguageAvailability(source: Locale.Language, target: Locale.Language) async -> LanguageAvailability {
        // Check if languages are in supported list
        let supportedLanguages = await getSupportedLanguages()

        let sourceSupported = supportedLanguages.contains { $0.language.minimalIdentifier == source.minimalIdentifier }
        let targetSupported = supportedLanguages.contains { $0.language.minimalIdentifier == target.minimalIdentifier }

        guard sourceSupported && targetSupported else {
            return .unsupported
        }

        // Check if downloaded
        let sourceAvailable = await isLanguageDownloaded(language: source)
        let targetAvailable = await isLanguageDownloaded(language: target)

        if sourceAvailable && targetAvailable {
            return .available
        } else {
            return .needsDownload
        }
    }
}

//
//  ConversationViewModel.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation
import Speech
import Translation
import Combine

/// Manages state and logic for real-time conversation translation
@MainActor
class ConversationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var myLanguage: Locale.Language = .english
    @Published var theirLanguage: Locale.Language = .spanish
    @Published var messages: [ConversationMessage] = []
    @Published var isListening: Bool = false
    @Published var currentTranscript: String = ""
    @Published var currentSpeaker: ConversationMessage.Speaker = .me
    @Published var audioLevel: Float = 0.0
    @Published var autoPlayTranslation: Bool = true
    @Published var errorMessage: String?
    @Published var isAuthorized: Bool = false
    @Published var showPermissionAlert: Bool = false
    @Published var autoDetectSpeaker: Bool = true  // NEW: Auto-detect who is speaking
    @Published var splitScreenMode: Bool = false   // NEW: Split-screen conversation mode

    // MARK: - Private Properties

    private let speechRecognitionManager = SpeechRecognitionManager()
    private let translationService: TranslationService
    private let speechManager: SpeechManager
    private let languageDetectionManager = LanguageDetectionManager()
    private var cancellables = Set<AnyCancellable>()
    private let maxMessages = 100

    // MARK: - Initialization

    init(translationService: TranslationService = TranslationService(),
         speechManager: SpeechManager = SpeechManager.shared) {
        self.translationService = translationService
        self.speechManager = speechManager

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe speech recognition state
        speechRecognitionManager.$isRecording
            .assign(to: &$isListening)

        speechRecognitionManager.$audioLevel
            .assign(to: &$audioLevel)

        speechRecognitionManager.$transcript
            .assign(to: &$currentTranscript)

        speechRecognitionManager.$errorMessage
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Requests necessary permissions for speech recognition
    func requestPermissions() async {
        let granted = await speechRecognitionManager.requestAuthorization()
        isAuthorized = granted

        if !granted {
            showPermissionAlert = true
        }
    }

    /// Starts listening for conversation
    func startListening() {
        guard isAuthorized else {
            Task {
                await requestPermissions()
            }
            return
        }

        errorMessage = nil

        do {
            let language = currentSpeaker == .me ? myLanguage : theirLanguage

            try speechRecognitionManager.startRecording(
                language: language,
                continuous: true,
                onResult: { [weak self] transcript in
                    Task { @MainActor in
                        await self?.processRecognizedSpeech(transcript)
                    }
                }
            )
        } catch {
            errorMessage = "Microphone Error:\n• Check Settings > Privacy > Microphone\n• Grant Lingo-lens access\n• Close other apps using the microphone"
        }
    }

    /// Stops listening
    func stopListening() {
        speechRecognitionManager.stopRecording()
        currentTranscript = ""
    }

    /// Toggles between speakers
    func toggleSpeaker() {
        // Stop current recording
        if isListening {
            stopListening()
        }

        // Switch speaker
        currentSpeaker = currentSpeaker == .me ? .them : .me

        // Haptic feedback for speaker change
        HapticManager.shared.speakerChange()

        // Restart recording with new language
        if isListening {
            startListening()
        }
    }

    /// Processes recognized speech and translates it
    /// Now with automatic speaker detection based on language
    func processRecognizedSpeech(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Auto-detect speaker if enabled
        if autoDetectSpeaker {
            detectAndSetSpeaker(from: text)
        }

        let sourceLanguage = currentSpeaker == .me ? myLanguage : theirLanguage
        let targetLanguage = currentSpeaker == .me ? theirLanguage : myLanguage

        do {
            // Create translation session
            let configuration = TranslationSession.Configuration(
                source: sourceLanguage,
                target: targetLanguage
            )

            let session = TranslationSession(configuration: configuration)
            let response = try await session.translate(text)

            // Create message
            let message = ConversationMessage(
                originalText: text,
                translatedText: response.targetText,
                sourceLanguage: sourceLanguage.minimalIdentifier,
                targetLanguage: targetLanguage.minimalIdentifier,
                speaker: currentSpeaker
            )

            // Add to messages
            addMessage(message)

            // Haptic feedback for successful translation
            HapticManager.shared.translationSuccess()

            // Play translation if enabled
            if autoPlayTranslation {
                playTranslation(for: message)
            }

        } catch {
            errorMessage = "Translation Failed:\n• Check your internet connection\n• Download languages for offline use\n• Try again in a moment"
        }
    }

    /// Detects the speaker based on the language of the text
    private func detectAndSetSpeaker(from text: String) {
        // Detect language of spoken text
        if let detectedLanguage = languageDetectionManager.detectLanguage(text: text) {
            let myLangCode = myLanguage.minimalIdentifier
            let theirLangCode = theirLanguage.minimalIdentifier

            // Check which language matches better
            if detectedLanguage.minimalIdentifier == myLangCode {
                let previousSpeaker = currentSpeaker
                currentSpeaker = .me
                Logger.debug("Auto-detected speaker: Me (\(myLangCode))")

                // Haptic feedback only if speaker actually changed
                if previousSpeaker != .me {
                    HapticManager.shared.speakerChange()
                }
            } else if detectedLanguage.minimalIdentifier == theirLangCode {
                let previousSpeaker = currentSpeaker
                currentSpeaker = .them
                Logger.debug("Auto-detected speaker: Them (\(theirLangCode))")

                // Haptic feedback only if speaker actually changed
                if previousSpeaker != .them {
                    HapticManager.shared.speakerChange()
                }
            }
            // If neither matches perfectly, keep current speaker
        }
    }

    /// Adds a message to the conversation
    func addMessage(_ message: ConversationMessage) {
        messages.append(message)

        // Limit message count
        if messages.count > maxMessages {
            messages = Array(messages.suffix(maxMessages))
        }
    }

    /// Plays the translation audio for a message
    func playTranslation(for message: ConversationMessage) {
        let targetLang = Locale.Language(identifier: message.targetLanguage)
        speechManager.speak(text: message.translatedText, language: targetLang)
    }

    /// Clears the conversation
    func clearConversation() {
        messages.removeAll()
        currentTranscript = ""
    }

    /// Exports conversation as text
    func exportConversation() -> String {
        messages.exportToText()
    }

    /// Exports conversation as JSON
    func exportConversationJSON() -> String? {
        messages.exportToJSON()
    }

    /// Swaps my language and their language
    func swapLanguages() {
        let temp = myLanguage
        myLanguage = theirLanguage
        theirLanguage = temp

        // Haptic feedback for language swap
        HapticManager.shared.selection()
    }
}

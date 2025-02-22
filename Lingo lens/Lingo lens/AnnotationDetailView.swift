//
//  AnnotationDetailView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//

import SwiftUI
import Translation
import AVFoundation

struct AnnotationDetailView: View {
    @EnvironmentObject var translationService: TranslationService
    /// The original text is always in English (from object detection)
    let originalText: String
    /// The target language selected by the user (default is Spanish)
    let targetLanguage: AvailableLanguage

    // Local state for the translated text.
    @State private var translatedText: String = ""
    // State to indicate translation progress.
    @State private var isTranslating: Bool = false
    // Trigger flag to launch the hidden translationTask.
    @State private var shouldTranslate: Bool = false
    // Translation configuration; will be set in onAppear.
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack(spacing: 16) {
            Text("Original: \(originalText)")
                .font(.headline)
            
            if !translatedText.isEmpty {
                Text("Translated:")
                    .font(.subheadline)
                Text(translatedText)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if isTranslating {
                ProgressView("Translating...")
            }
            
            // Button to trigger translation.
            Button("Translate") {
                guard configuration != nil else { return }
                isTranslating = true
                shouldTranslate = true
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.white)
            .disabled(isTranslating || originalText.isEmpty)
            
            // Once translated, show a button to hear pronunciation.
            if !translatedText.isEmpty {
                Button(action: {
                    let utterance = AVSpeechUtterance(string: translatedText)
                    let langCode = targetLanguage.shortName() // e.g. "es-US"
                    utterance.voice = AVSpeechSynthesisVoice(language: langCode)
                    AVSpeechSynthesizer().speak(utterance)
                }) {
                    Label("Hear Pronunciation", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if configuration == nil {
                // Initialize the configuration with the source and target languages
                configuration = TranslationSession.Configuration(
                    source: translationService.sourceLanguage,
                    target: targetLanguage.locale
                )
            }
        }
        .background(
            Group {
                if shouldTranslate, let config = configuration {
                    Text("")
                        .translationTask(config) { session in
                            do {
                                try await translationService.translate(text: originalText, using: session)
                                translatedText = translationService.translatedText
                            } catch {
                                translatedText = "Translation error"
                                print("Translation error: \(error)")
                            }
                            isTranslating = false
                            shouldTranslate = false
                        }
                }
            }
            .hidden()
        )
    }
}

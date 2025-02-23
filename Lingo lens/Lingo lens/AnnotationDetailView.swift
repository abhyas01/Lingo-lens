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
    @Environment(\.dismiss) private var dismiss
    let originalText: String
    let targetLanguage: AvailableLanguage

    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: Bool = false
    @State private var shouldTranslate: Bool = false
    @State private var configuration: TranslationSession.Configuration?
    @State private var showDownloadAlert: Bool = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 24) {
            // Header with close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Original Text Section
                    VStack(spacing: 12) {
                        Text("Original Word")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Text(originalText)
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Translation Results Area
                    Group {
                        if !translatedText.isEmpty && !translationError {
                            VStack(spacing: 12) {
                                Text("Translation")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                Text(translatedText)
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Button(action: speakTranslation) {
                                    Label("Listen", systemImage: "speaker.wave.2.fill")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if isTranslating {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Translating...")
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity, minHeight: 150)
                        }
                        
                        if translationError {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.red)
                                
                                Text("Translation failed")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                
                                Text("Try downloading the language or translate again")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    Button("Download Language") {
                                        showDownloadAlert = true
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("Try Again") {
                                        startTranslation()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .frame(minHeight: 150)
                    
                    if !isTranslating && !translationError && translatedText.isEmpty {
                        Button(action: startTranslation) {
                            Text("Translate")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear(perform: setupConfiguration)
        .background(translationTaskBackground)
        .alert("Download Language", isPresented: $showDownloadAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Please go to Settings > Translate > Downloaded Languages to add this language.")
        }
    }

    // MARK: - Translation Logic
    private func startTranslation() {
        guard configuration != nil else { return }
        guard translationService.sourceLanguage != targetLanguage.locale else {
            showError(message: "Can't translate to same language")
            return
        }
        
        resetState()
        isTranslating = true
        shouldTranslate = true
    }
    
    private func resetState() {
        translatedText = ""
        translationError = false
    }
    
    private func showError(message: String) {
         translatedText = message
         translationError = true
         isTranslating = false
     }
    
    // MARK: - Speech Synthesis
    
    private func speakTranslation() {
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: translatedText)
        let langCode = targetLanguage.locale.languageCode?.debugDescription
        
        utterance.voice = AVSpeechSynthesisVoice(language: langCode) ??
            AVSpeechSynthesisVoice(language: targetLanguage.locale.languageCode?.debugDescription ?? "en-US")
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0
        
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Configuration
    private func setupConfiguration() {
        if configuration == nil {
            configuration = TranslationSession.Configuration(
                source: translationService.sourceLanguage,
                target: targetLanguage.locale
            )
        }
    }
    
    // MARK: - Settings Navigation
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - Translation Task
    private var translationTaskBackground: some View {
        Group {
            if shouldTranslate, let config = configuration {
                Text("")
                    .translationTask(config) { session in
                        do {
                            try await translationService.translate(text: originalText, using: session)
                            translatedText = translationService.translatedText
                            translationError = false
                        } catch {
                            translatedText = "Translation failed. Try downloading the language."
                            translationError = true
                        }
                        isTranslating = false
                        shouldTranslate = false
                    }
            }
        }
        .hidden()
    }
}

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
    let originalText: String
    let targetLanguage: AvailableLanguage
    // No need to store the session; we only keep the configuration.
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack(spacing: 16) {
            Text("Original: \(originalText)")
                .font(.headline)
            
            // Use the translationTask view modifier, which provides a TranslationSession instance.
            Text(translationService.translatedText)
                .italic()
                .multilineTextAlignment(.center)
                .padding()
                .translationTask(configuration) { session in
                    do {
                        try await translationService.translate(text: originalText, using: session)
                    } catch {
                        print("Translation error: \(error)")
                    }
                }
            
            Button(action: {
                let utterance = AVSpeechUtterance(string: translationService.translatedText)
                // Use our AvailableLanguage's shortName() to produce a BCP-47 string.
                let langCode = targetLanguage.shortName()
                utterance.voice = AVSpeechSynthesisVoice(language: langCode)
                AVSpeechSynthesizer().speak(utterance)
            }) {
                Label("Hear Pronunciation", systemImage: "speaker.wave.2")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Initialize configuration if needed.
            if configuration == nil {
                configuration = TranslationSession.Configuration(target: targetLanguage.locale)
            }
        }
    }
}

struct AnnotationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AnnotationDetailView(
            originalText: "Hello World",
            targetLanguage: AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "US"))
        )
        .environmentObject(TranslationService())
    }
}

//
//  SavedTranslationDetailView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//


import SwiftUI
import AVFoundation

struct SavedTranslationDetailView: View {
    let translation: SavedTranslation
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(translation.languageCode?.toFlagEmoji() ?? "🌐")
                            .font(.system(size: 70))
                        
                        Text(translation.languageName ?? "Unknown language")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    VStack(spacing: 12) {
                        Text("Original Word")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Text(translation.originalText ?? "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Text("Translation")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Text(translation.translatedText ?? "")
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
                        .accessibilityLabel("Listen to pronunciation")
                        .accessibilityHint("Hear how \(translation.translatedText ?? "") is pronounced")
                    }
                    .padding(.horizontal)
                    
                    if let date = translation.dateAdded {
                        Text("Saved on \(date.toMediumDateTimeString())")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 12)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func speakTranslation() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: translation.translatedText ?? "")
        let langCode = (translation.languageCode ?? "").split(separator: "-").first ?? "en"
        
        utterance.voice = AVSpeechSynthesisVoice(language: String(langCode)) ??
                         AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0
        
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    let viewContext = PersistenceController.preview.container.viewContext
    let translation = SavedTranslation(context: viewContext)
    translation.id = UUID()
    translation.originalText = "Hello"
    translation.translatedText = "Hola"
    translation.languageCode = "es-ES"
    translation.languageName = "Spanish (es-ES)"
    translation.dateAdded = Date()
    
    return SavedTranslationDetailView(translation: translation)
}

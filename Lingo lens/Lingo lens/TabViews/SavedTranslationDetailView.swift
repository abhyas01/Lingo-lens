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
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    
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
                    
                    VStack {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .accessibilityLabel("Delete translation")
                        .accessibilityHint("Removes this translation from your saved words")
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    
                    
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
        .alert("Delete Translation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTranslation()
            }
        } message: {
            Text("Are you sure you want to delete this translation? This action cannot be undone.")
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
    
    private func deleteTranslation() {
        // Delete from Core Data
        viewContext.delete(translation)
        
        do {
            try viewContext.save()
            // Dismiss the view after successful delete
            dismiss()
        } catch {
            print("Error deleting translation: \(error.localizedDescription)")
            // You could add an error alert here if desired
        }
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

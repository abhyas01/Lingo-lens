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
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var speechManager = SpeechManager.shared
    
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
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
                            HStack {
                                if speechManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                    Text("Loading...")
                                } else if speechManager.isSpeaking {
                                    Image(systemName: "speaker.wave.3.fill")
                                    Text("Playing")
                                } else {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("Listen")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                speechManager.isLoading ? Color.white :
                                    speechManager.isSpeaking ? Color.orange : Color.blue
                            )
                            .cornerRadius(12)
                        }
                        .disabled(speechManager.isLoading)
                        .accessibilityLabel(
                            speechManager.isLoading ? "Loading audio" :
                            speechManager.isSpeaking ? "Currently playing" : "Listen to pronunciation"
                        )
                        .accessibilityHint("Hear how \(translation.translatedText ?? "") is pronounced in \(translation.languageCode ?? "")")
                    }
                    .padding(.horizontal)
                    
                    VStack {
                        if isDeleting {
                            Button(action: {}) {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Deleting...")
                                        .padding(.leading, 8)
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                            }
                            .disabled(true)
                        } else {
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
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    
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
        .withSpeechErrorHandling()
        .alert("Delete Translation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTranslation()
            }
        } message: {
            Text("Are you sure you want to delete this translation? This action cannot be undone.")
        }
        .alert("Delete Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
        .disabled(isDeleting)
        .animation(.spring(response: 0.3), value: isDeleting)
        .onDisappear {
            SpeechManager.shared.stopSpeaking()
        }
    }
    
    private func speakTranslation() {
        SpeechManager.shared.speak(
            text: translation.translatedText ?? "",
            languageCode: translation.languageCode ?? "en-US"
        )
    }
    
    private func deleteTranslation() {
        isDeleting = true
        
        Task {
            do {
                await MainActor.run {
                    viewContext.delete(translation)
                }
                
                try viewContext.save()
                
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteErrorMessage = "Unable to delete translation. Please try again later."
                    showDeleteError = true
                }
            }
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

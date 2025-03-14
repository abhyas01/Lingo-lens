//
//  SavedTranslationDetailView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/9/25.
//

import SwiftUI
import AVFoundation

/// Detailed view for a saved translation item
/// Shows original text, translation, pronunciation controls and delete option
struct SavedTranslationDetailView: View {
    
    // The saved translation from Core Data to display
    let translation: SavedTranslation
    
    // Access to Core Data view context for saving/deleting
    @Environment(\.managedObjectContext) private var viewContext
    
    // For dismissing this view when user is done or after deleting
    @Environment(\.dismiss) private var dismiss
    
    // Shared speech manager to handle pronunciation
    @ObservedObject private var speechManager = SpeechManager.shared
    
    // MARK: - State Properties
    
    // Controls the delete confirmation alert visibility
    @State private var showDeleteConfirmation = false
    
    // Shows loading indicator during deletion
    @State private var isDeleting = false
    
    // Error handling for deletion failures
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Language information section with flag and name
                    VStack(spacing: 8) {
                        Text(translation.languageCode?.toFlagEmoji() ?? "🌐")
                            .font(.system(size: 70))
                        
                        Text(translation.languageName ?? "Unknown language")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Original word/text section
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
                    
                    // Translated text section with pronunciation button
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
                        
                        // Dynamic pronunciation button that shows different states
                        Button(action: speakTranslation) {
                            HStack {
                                if speechManager.isLoading {
                                    
                                    // Loading state while preparing audio
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                    Text("Loading...")
                                } else if speechManager.isSpeaking {
                                    
                                    // Currently speaking state
                                    Image(systemName: "speaker.wave.3.fill")
                                    Text("Playing")
                                } else {
                                    
                                    // Ready to speak state
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
                    
                    // Delete button section with loading state
                    VStack {
                        if isDeleting {
                            
                            // Show progress indicator while deleting
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
                            
                            // Normal delete button
                            Button(action: {
                                print("👆 Button pressed: Show delete confirmation for translation")
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
                    
                    // Timestamp footer showing when translation was saved
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
        
        // Apply speech error handling to show alerts if pronunciation fails
        .withSpeechErrorHandling()
        
        // Delete confirmation alert
        .alert("Delete Translation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTranslation()
            }
        } message: {
            Text("Are you sure you want to delete this translation? This action cannot be undone.")
        }
        
        // Error alert if deletion fails
        .alert("Delete Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
        
        // Disable entire view during deletion to prevent multiple actions
        .disabled(isDeleting)
        
        // Animate state changes for smoother UX
        .animation(.spring(response: 0.3), value: isDeleting)
        
        // Stop any ongoing speech when view disappears
        .onDisappear {
            SpeechManager.shared.stopSpeaking()
        }
    }
    
    /// Triggers text-to-speech to pronounce the translated text
    /// Uses the target language's voice settings
    private func speakTranslation() {
        print("👆 Button pressed: Speak translation \"\(translation.translatedText ?? "")\" in language: \(translation.languageCode ?? "unknown")")
        SpeechManager.shared.speak(
            text: translation.translatedText ?? "",
            languageCode: translation.languageCode ?? "en-US"
        )
    }
    
    /// Deletes the current translation from Core Data
    /// Handles error states and dismisses view on success
    private func deleteTranslation() {
        print("🗑️ Deleting translation: \(translation.originalText ?? "unknown") -> \(translation.translatedText ?? "unknown")")
        isDeleting = true
        
        Task {
            do {
                
                // Delete on main thread since it affects UI
                await MainActor.run {
                    print("🗑️ Removing translation from context: ID \(translation.id?.uuidString ?? "unknown")")
                    viewContext.delete(translation)
                }
                
                // Save context to persist the deletion
                try viewContext.save()
                print("✅ Translation deleted and context saved")
                
                // Return to list view on successful delete
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                print("❌ Failed to delete translation: \(error.localizedDescription)")

                // Show error if deletion fails
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

//
//  AnnotationDetailView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import Translation
import AVFoundation
import CoreData

/// Detail view shown when user taps on an annotation
/// Displays the original text and its translation with pronunciation features
struct AnnotationDetailView: View {
    @EnvironmentObject var translationService: TranslationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
     
    @ObservedObject private var speechManager = SpeechManager.shared

    // Text from the tapped AR annotation
    let originalText: String
    
    // Language to translate into
    let targetLanguage: AvailableLanguage

    // MARK: - State Properties

    // Translation results and state
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: Bool = false
    @State private var shouldTranslate: Bool = true
    @State private var configuration: TranslationSession.Configuration?
    
    // Alert states
    @State private var showDownloadAlert: Bool = false
    @State private var showLongLoadingWarning: Bool = false
    @State private var showSavedConfirmation: Bool = false
    
    // Saved state tracking
    @State private var isAlreadySaved: Bool = false
    @State private var isCheckingSavedStatus: Bool = false
    @State private var isSavingTranslation: Bool = false
    @State private var showCoreDataError: Bool = false
    @State private var coreDataErrorMessage: String = ""
    
    // How long to wait before showing "taking longer than usual" message
    let loadingTimeout: TimeInterval = 10

    var body: some View {
        VStack(spacing: 24) {
            
            // Close button in top-right corner
            HStack {
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .accessibilityLabel("Close Translation")

            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Original word section - always visible
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
                    
                    
                    Group {
                        
                        // Translation result section - shown when translation is complete
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
                                
                                // Audio playback and save buttons
                                HStack(spacing: 12) {
                                    
                                    // Listen button with dynamic appearance based on speech state
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
                                    .accessibilityHint("Hear how \(translatedText) is pronounced in \(targetLanguage.shortName())")
                                    
                                    // Save button in various states
                                    if isCheckingSavedStatus {
                                        
                                        // Checking if already saved
                                        Button(action: {}) {
                                            HStack {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(.white)
                                                Text("Checking")
                                            }
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.orange.opacity(0.8))
                                            .cornerRadius(12)
                                        }
                                        .disabled(true)
                                    } else if isSavingTranslation {
                                        
                                        // Currently saving
                                        Button(action: {}) {
                                            HStack {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(.white)
                                                Text("Saving")
                                            }
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.orange.opacity(0.8))
                                            .cornerRadius(12)
                                        }
                                        .disabled(true)
                                    } else {
                                        
                                        // Normal save button or already saved indicator
                                        Button(action: isAlreadySaved ? {} : saveTranslation) {
                                            Label(isAlreadySaved || showSavedConfirmation ? "Saved" : "Save",
                                                  systemImage: isAlreadySaved || showSavedConfirmation ? "checkmark" : "bookmark.fill")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(isAlreadySaved || showSavedConfirmation ? Color.green : Color.orange)
                                                .cornerRadius(12)
                                        }
                                        .accessibilityLabel(isAlreadySaved ? "Already saved" : "Save translation")
                                        .accessibilityHint(isAlreadySaved ? "This translation is already saved to your collection" : "Save this translation to your collection")
                                        .disabled(isAlreadySaved || showSavedConfirmation)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Loading indicator - shown during translation
                        if isTranslating {
                            VStack(spacing: 16) {
                                
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .accessibilityLabel("Translation in progress")
                                    .accessibilityValue(showLongLoadingWarning ? "Taking longer than usual" : "")
                                
                                Text("Translating...")
                                    .foregroundStyle(.gray)
                                
                                // Shows after loadingTimeout seconds if still translating
                                if showLongLoadingWarning {
                                    VStack(spacing: 8) {
                                        Text("Taking longer than usual...")
                                            .foregroundStyle(.gray)
                                        
                                        Button("Close and try again") {
                                            dismiss()
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 150)
                        }
                        
                        // Error state - shown when translation fails
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
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Translation Error")
                            .accessibilityHint("Choose to download language or try again")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .frame(minHeight: 150)
                }
            }
        }
        .withSpeechErrorHandling()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            setupConfiguration()
            startTranslation()
            checkIfAlreadySaved()
            
            // Setup timeout warning if translation takes too long
            DispatchQueue.main.asyncAfter(deadline: .now() + loadingTimeout) {
                if isTranslating {
                    showLongLoadingWarning = true
                }
            }
        }
        .onDisappear {
            SpeechManager.shared.stopSpeaking()
        }
        .onChange(of: isTranslating) { oldValue, newValue in
            if !newValue {
                showLongLoadingWarning = false
            }
        }
        .onChange(of: translatedText) { oldValue, newValue in
            if !newValue.isEmpty && !translationError {
                checkIfAlreadySaved()
            }
        }
        .background(translationTaskBackground)
        .alert("Download Language", isPresented: $showDownloadAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Please go to: Settings > Apps > Translate > Downloaded Languages.\nThen download this language.")
        }
        .alert("Storage Error", isPresented: $showCoreDataError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(coreDataErrorMessage)
        }
        .animation(.spring(response: 0.3), value: showSavedConfirmation)
        .animation(.spring(response: 0.3), value: isAlreadySaved)
        .animation(.spring(response: 0.3), value: isCheckingSavedStatus)
        .animation(.spring(response: 0.3), value: isSavingTranslation)
    }
    
    // MARK: - CoreData Integration

    /// Checks if the current translation is already saved in CoreData
    /// Updates isAlreadySaved state accordingly
    private func checkIfAlreadySaved() {
        guard !translatedText.isEmpty, !originalText.isEmpty else { return }
        
        isCheckingSavedStatus = true
        
        // Build query to find matching translations
        let fetchRequest: NSFetchRequest<SavedTranslation> = SavedTranslation.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "originalText == %@ AND translatedText == %@ AND languageCode == %@",
            originalText, translatedText, targetLanguage.shortName()
        )
        fetchRequest.fetchLimit = 1
        
        Task {
            do {
                let matches = try viewContext.fetch(fetchRequest)
                
                await MainActor.run {
                    isAlreadySaved = !matches.isEmpty
                    isCheckingSavedStatus = false
                }
            } catch {
                await MainActor.run {
                    isCheckingSavedStatus = false
                    showCoreDataErrorAlert(message: "Unable to check if this translation is already saved. Please try again.")
                }
            }
        }
    }
    
    /// Saves the current translation to CoreData
    /// Updates UI states for success/failure
    private func saveTranslation() {
        isSavingTranslation = true
        
        Task {
            do {
                await MainActor.run {
                    let newTranslation = SavedTranslation(context: viewContext)
                    
                    newTranslation.id = UUID()
                    newTranslation.originalText = originalText
                    newTranslation.translatedText = translatedText
                    newTranslation.languageCode = targetLanguage.shortName()
                    newTranslation.languageName = targetLanguage.localizedName()
                    newTranslation.dateAdded = Date()
                }
                
                try viewContext.save()
                
                await MainActor.run {
                    isSavingTranslation = false
                    withAnimation {
                        showSavedConfirmation = true
                        isAlreadySaved = true
                    }
                    
                    // Hide confirmation after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showSavedConfirmation = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSavingTranslation = false
                    showCoreDataErrorAlert(message: "Unable to save translation. Please try again later.")
                }
            }
        }
    }
    
    /// Shows CoreData error alert with custom message
    private func showCoreDataErrorAlert(message: String) {
        coreDataErrorMessage = message
        showCoreDataError = true
    }
    
    // MARK: - Translation Handling

    /// Starts translation process if needed
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
    
    /// Resets all state variables to default values
    private func resetState() {
        translatedText = ""
        translationError = false
        isAlreadySaved = false
        isCheckingSavedStatus = false
        isSavingTranslation = false
    }
    
    /// Shows error message with error styling
    private func showError(message: String) {
         translatedText = message
         translationError = true
         isTranslating = false
     }
    
    /// Speaks the translated text using SpeechManager
    private func speakTranslation() {
        SpeechManager.shared.speak(
            text: translatedText,
            languageCode: targetLanguage.shortName()
        )
    }

    /// Initializes translation configuration for the target language
    private func setupConfiguration() {
        if configuration == nil {
            configuration = TranslationSession.Configuration(
                source: translationService.sourceLanguage,
                target: targetLanguage.locale
            )
        }
    }
    
    /// Opens system settings to manage translation downloads
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    /// Background view that performs actual translation
    /// Hidden from UI but handles the translation process
    private var translationTaskBackground: some View {
        Group {
            if shouldTranslate, let config = configuration {
                Text("")
                    .translationTask(config) { session in
                        do {
                            try await translationService.translate(text: originalText, using: session)
                            translatedText = translationService.translatedText
                            translationError = false
                        
                            checkIfAlreadySaved()
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

#Preview("Sample Translation") {
    let translationService = TranslationService()
    translationService.translatedText = "Mesa"
    
    let targetLanguage = AvailableLanguage(
        locale: .init(languageCode: "es", region: "ES")
    )
    
    return AnnotationDetailView(
        originalText: "Table",
        targetLanguage: targetLanguage
    )
    .environmentObject(translationService)
    .environmentObject(AppearanceManager())
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("No Translation Yet") {
    let translationService = TranslationService()
    
    let targetLanguage = AvailableLanguage(
        locale: .init(languageCode: "es", region: "ES")
    )
    
    return AnnotationDetailView(
        originalText: "Chair",
        targetLanguage: targetLanguage
    )
    .environmentObject(translationService)
    .environmentObject(AppearanceManager())
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Translation Failed") {
    let translationService = TranslationService()
    translationService.translatedText = "Translation failed. Try downloading the language."
    
    let targetLanguage = AvailableLanguage(
        locale: .init(languageCode: "es", region: "ES")
    )
    
    return AnnotationDetailView(
        originalText: "Window",
        targetLanguage: targetLanguage
    )
    .environmentObject(translationService)
    .environmentObject(AppearanceManager())
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

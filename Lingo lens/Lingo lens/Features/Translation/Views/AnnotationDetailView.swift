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

struct AnnotationDetailView: View {
    @EnvironmentObject var translationService: TranslationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
     
    let originalText: String
    let targetLanguage: AvailableLanguage

    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: Bool = false
    @State private var shouldTranslate: Bool = true
    @State private var configuration: TranslationSession.Configuration?
    @State private var showDownloadAlert: Bool = false
    @State private var showLongLoadingWarning: Bool = false
    @State private var showSavedConfirmation: Bool = false
    @State private var isAlreadySaved: Bool = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    @State private var isCheckingSavedStatus: Bool = false
    @State private var isSavingTranslation: Bool = false
    @State private var showCoreDataError: Bool = false
    @State private var coreDataErrorMessage: String = ""
    
    let loadingTimeout: TimeInterval = 10

    var body: some View {
        VStack(spacing: 24) {
            
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
                                
                                HStack(spacing: 12) {
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
                                    .accessibilityHint("Hear how \(translatedText) is pronounced in \(targetLanguage.localizedName())")
                                    
                                    if isCheckingSavedStatus {
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
                        
                        if isTranslating {
                            VStack(spacing: 16) {
                                
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .accessibilityLabel("Translation in progress")
                                    .accessibilityValue(showLongLoadingWarning ? "Taking longer than usual" : "")
                                
                                Text("Translating...")
                                    .foregroundStyle(.gray)
                                
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            setupConfiguration()
            startTranslation()
            checkIfAlreadySaved()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + loadingTimeout) {
                if isTranslating {
                    showLongLoadingWarning = true
                }
            }
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
    
    private func checkIfAlreadySaved() {
        guard !translatedText.isEmpty, !originalText.isEmpty else { return }
        
        isCheckingSavedStatus = true
        
        let fetchRequest: NSFetchRequest<SavedTranslation> = SavedTranslation.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "originalText == %@ AND translatedText == %@ AND languageCode == %@",
            originalText, translatedText, targetLanguage.shortName()
        )
        fetchRequest.fetchLimit = 1
        
        // Use background task for database operation
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
    
    private func showCoreDataErrorAlert(message: String) {
        coreDataErrorMessage = message
        showCoreDataError = true
    }
    
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
        isAlreadySaved = false
        isCheckingSavedStatus = false
        isSavingTranslation = false
    }
    
    private func showError(message: String) {
         translatedText = message
         translationError = true
         isTranslating = false
     }
    
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

    private func setupConfiguration() {
        if configuration == nil {
            configuration = TranslationSession.Configuration(
                source: translationService.sourceLanguage,
                target: targetLanguage.locale
            )
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private var translationTaskBackground: some View {
        Group {
            if shouldTranslate, let config = configuration {
                Text("")
                    .translationTask(config) { session in
                        do {
                            try await translationService.translate(text: originalText, using: session)
                            translatedText = translationService.translatedText
                            translationError = false
                            
                            // Check if already saved once translation completes
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

#Preview {
    let translationService = TranslationService()
    translationService.translatedText = "Mesa"
    
    let targetLanguage = AvailableLanguage(
        locale: Locale.Language(languageCode: "es", region: "ES")
    )
    
    return Group {
        
        AnnotationDetailView(
            originalText: "Table",
            targetLanguage: targetLanguage
        )
        .environmentObject(translationService)
        
        
        AnnotationDetailView(
            originalText: "Chair",
            targetLanguage: targetLanguage
        )
        .environmentObject(translationService)
        .onAppear {
            translationService.translatedText = ""
        }
        
    
        AnnotationDetailView(
            originalText: "Window",
            targetLanguage: targetLanguage
        )
        .environmentObject(translationService)
        .onAppear {
            translationService.translatedText = "Translation failed. Try downloading the language."
        }
    }
}

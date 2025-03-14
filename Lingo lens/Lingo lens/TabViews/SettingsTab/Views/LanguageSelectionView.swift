//
//  LanguageSelectionView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//

import SwiftUI
import Translation

/// View for selecting the target translation language
/// Displays a list of available languages and handles language downloads
struct LanguageSelectionView: View {
    
    // Dismisses the view when selection is complete
    @Environment(\.dismiss) private var dismiss
    
    // Access to the app's translation service
    @EnvironmentObject var translationService: TranslationService
    
    // The selected language binding passed from parent view
    @Binding var selectedLanguage: AvailableLanguage
    
    // Temporary storage for language selection before confirming
    @State private var tempSelectedLanguage: AvailableLanguage
    
    // MARK: - State Properties

    // Tracks if we're currently downloading language data
    @State private var isDownloading = false
    
    // Error state for download failures
    @State private var showDownloadError = false
    
    // Configuration for translation task
    @State private var downloadConfig: TranslationSession.Configuration? = nil
    
    /// Initialize with the currently selected language
    /// Sets up temp language for selection changes
    init(selectedLanguage: Binding<AvailableLanguage>) {
        self._selectedLanguage = selectedLanguage
        self._tempSelectedLanguage = State(initialValue: selectedLanguage.wrappedValue)
    }
    
    var body: some View {
        
        // List of available languages with checkmark for selected one
        List(translationService.availableLanguages, id: \.id) { language in
            HStack {
                Text(language.localizedName())
                Spacer()
                if language.shortName() == tempSelectedLanguage.shortName() {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(language.localizedName())")
            .accessibilityValue(language.shortName() == tempSelectedLanguage.shortName() ? "Selected" : "")
            .accessibilityAddTraits(language.shortName() == tempSelectedLanguage.shortName() ? .isSelected : [])
            .contentShape(Rectangle())
            .onTapGesture {
                tempSelectedLanguage = language
            }
        }
        
        // If languages change while view is open, update selection if needed
        .onChange(of: translationService.availableLanguages) {
            if !translationService.availableLanguages.contains(where: { $0.shortName() == tempSelectedLanguage.shortName() }) {
                tempSelectedLanguage = translationService.availableLanguages.first ?? tempSelectedLanguage
            }
        }
        
        // Reset temp language to match current selection on appear
        .onAppear {
            tempSelectedLanguage = selectedLanguage
        }
        
        // Navigation bar setup
        .navigationTitle("Select Language")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    isDownloading = true
                    downloadConfig = TranslationSession.Configuration(
                        source: translationService.sourceLanguage,
                        target: tempSelectedLanguage.locale
                    )
                }
            }
        }
        
        // Loading overlay while preparing language
        .overlay(
            isDownloading ?
                VStack {
                    ProgressView("Preparing language...")
                    Text("This might take a moment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(10)
                : nil
        )
        .disabled(isDownloading)
        
        // Error alert if download fails
        .alert("Download Error", isPresented: $showDownloadError) {
            Button("OK") {
                selectedLanguage = tempSelectedLanguage
                dismiss()
            }
        } message: {
            Text("Unable to download language data. Translations may not work properly.")
        }
        
        // Hidden view that handles language download
        .translationTask(downloadConfig) { session in
            guard isDownloading else { return }
            
            do {
                
                // Try to prepare translation with selected language
                try await session.prepareTranslation()
            
                await MainActor.run {
                    isDownloading = false
                    selectedLanguage = tempSelectedLanguage
                    dismiss()
                    downloadConfig = nil
                }
            } catch {
                
                // Handle download failure
                await MainActor.run {
                    isDownloading = false
                    showDownloadError = true
                    downloadConfig = nil
                }
            }
        }
    }
}


#Preview {
    let sampleLanguage = AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES"))
    
    let translationService = TranslationService()
    translationService.availableLanguages = [
        AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: Locale.Language(languageCode: "de", region: "DE")),
        AvailableLanguage(locale: Locale.Language(languageCode: "it", region: "IT"))
    ]
    
    return NavigationView {
        LanguageSelectionView(selectedLanguage: .constant(sampleLanguage))
            .environmentObject(translationService)
    }
}

//
//  LanguageSelectionView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//

import SwiftUI
import Translation

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var translationService: TranslationService
    @Binding var selectedLanguage: AvailableLanguage
    @State private var tempSelectedLanguage: AvailableLanguage
    
    @State private var isDownloading = false
    @State private var showDownloadError = false
    @State private var downloadConfig: TranslationSession.Configuration? = nil
    
    init(selectedLanguage: Binding<AvailableLanguage>) {
        self._selectedLanguage = selectedLanguage
        self._tempSelectedLanguage = State(initialValue: selectedLanguage.wrappedValue)
    }
    
    var body: some View {
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
        
        .onChange(of: translationService.availableLanguages) {
            if !translationService.availableLanguages.contains(where: { $0.shortName() == tempSelectedLanguage.shortName() }) {
                tempSelectedLanguage = translationService.availableLanguages.first ?? tempSelectedLanguage
            }
        }
        
        .onAppear {
            tempSelectedLanguage = selectedLanguage
        }
        
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
        .alert("Download Error", isPresented: $showDownloadError) {
            Button("OK") {
                selectedLanguage = tempSelectedLanguage
                dismiss()
            }
        } message: {
            Text("Unable to download language data. Translations may not work properly.")
        }
        .translationTask(downloadConfig) { session in
            guard isDownloading else { return }
            
            do {
                try await session.prepareTranslation()
            
                await MainActor.run {
                    isDownloading = false
                    selectedLanguage = tempSelectedLanguage
                    dismiss()
                    downloadConfig = nil
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    showDownloadError = true
                    downloadConfig = nil
                }
            }
        }
    }
}


struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleLanguage = AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES"))
        
        LanguageSelectionView(
            selectedLanguage: .constant(sampleLanguage))
        .environmentObject({
            let service = TranslationService()
            service.availableLanguages = [
                AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES")),
                AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR")),
                AvailableLanguage(locale: Locale.Language(languageCode: "de", region: "DE")),
                AvailableLanguage(locale: Locale.Language(languageCode: "it", region: "IT"))
            ]
            return service
        }())
    }
}

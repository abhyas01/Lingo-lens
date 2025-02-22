//
//  LanguageSelectionView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//


import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var translationService: TranslationService
    @Binding var selectedLanguage: AvailableLanguage
    @Binding var isPresented: Bool
    @State private var tempSelectedLanguage: AvailableLanguage
    
    init(selectedLanguage: Binding<AvailableLanguage>, isPresented: Binding<Bool>) {
        self._selectedLanguage = selectedLanguage
        self._isPresented = isPresented
        self._tempSelectedLanguage = State(initialValue: selectedLanguage.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            List(translationService.availableLanguages, id: \.id) { language in
                HStack {
                    Text(language.localizedName())
                    Spacer()
                    if language.shortName() == tempSelectedLanguage.shortName() {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedLanguage = tempSelectedLanguage
                        isPresented = false
                    }
                }
            }
        }
    }
}

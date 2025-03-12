//
//  SettingsTabView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var arViewModel: ARViewModel
    @State private var showLanguageSelection = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Translation")) {
                    Button(action: {
                        showLanguageSelection = true
                    }) {
                        HStack {
                            Text("Language")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text(arViewModel.selectedLanguage.localizedName())
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Select Translation Language")
                    .accessibilityValue("Current language: \(arViewModel.selectedLanguage.localizedName())")
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .sheet(isPresented: $showLanguageSelection) {
                LanguageSelectionView(
                    selectedLanguage: $arViewModel.selectedLanguage,
                    isPresented: $showLanguageSelection
                )
            }
        }
    }
}

#Preview {
    let arViewModel = ARViewModel()
    arViewModel.selectedLanguage = AvailableLanguage(
        locale: Locale.Language(languageCode: "es", region: "ES")
    )
    
    let translationService = TranslationService()
    translationService.availableLanguages = [
        AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: Locale.Language(languageCode: "de", region: "DE"))
    ]
    
    return SettingsTabView(arViewModel: arViewModel)
            .environmentObject(translationService)
}

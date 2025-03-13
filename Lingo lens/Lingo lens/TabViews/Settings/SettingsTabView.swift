//
//  SettingsTabView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var arViewModel: ARViewModel
    @EnvironmentObject private var appearanceManager: AppearanceManager
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Translation")) {
                    NavigationLink {
                        LanguageSelectionView(
                            selectedLanguage: $arViewModel.selectedLanguage)
                    } label: {
                        HStack {
                            Text("Language")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text(arViewModel.selectedLanguage.localizedName())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.trailing, 5)
                    }
                    .accessibilityLabel("Select Translation Language")
                    .accessibilityValue("Current language: \(arViewModel.selectedLanguage.localizedName())")
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: $appearanceManager.colorSchemeOption) {
                        ForEach(AppearanceManager.ColorSchemeOption.allCases) { option in
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundColor(iconColor(for: option))
                                Text(option.title)
                            }
                            .tag(option)
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                    .accessibilityLabel("Choose Color Scheme")
                    .accessibilityHint("Select between light mode, dark mode, or system default")
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.blue)
                        Text("Version")
                        Spacer()
                        Text("\(version) (\(build))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
    }
    
    private func iconColor(for option: AppearanceManager.ColorSchemeOption) -> Color {
        switch option {
        case .system:
            return .gray
        case .light:
            return .yellow
        case .dark:
            return .blue
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
            .environmentObject(AppearanceManager())
}

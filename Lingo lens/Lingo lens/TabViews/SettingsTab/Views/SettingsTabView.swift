//
//  SettingsTabView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import SwiftUI

/// Main settings tab for the app
/// Provides options for language selection and appearance customization
struct SettingsTabView: View {
    
    // AR view model passed from parent view
    @ObservedObject var arViewModel: ARViewModel
    
    // Access to the app's appearance settings
    @EnvironmentObject private var appearanceManager: AppearanceManager
    
    // App version information from Info.plist
    // Used to display version number in settings
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    
    var body: some View {
        NavigationView {
            List {
                
                // MARK: - Translation Settings

                // Language selection section
                Section(header: Text("Translation")) {
                    NavigationLink {
                        LanguageSelectionView(
                            selectedLanguage: $arViewModel.selectedLanguage)
                    } label: {
                        HStack {
                            Text("Language")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // Show currently selected language
                            Text(arViewModel.selectedLanguage.localizedName())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.trailing, 5)
                    }
                    .accessibilityLabel("Select Translation Language")
                    .accessibilityValue("Current language: \(arViewModel.selectedLanguage.localizedName())")
                }
                
                // MARK: - Appearance Settings

                // Theme selection section (dark/light mode)
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: $appearanceManager.colorSchemeOption) {
                        ForEach(AppearanceManager.ColorSchemeOption.allCases) { option in
                            HStack {
                                
                                // Show icon for each theme option
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
                
                // MARK: - About Section

                // App version information
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
    
    /// Returns an appropriate color for each theme option icon
    /// Makes the icons visually represent their theme
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

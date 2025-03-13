//
//  ContentView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var translationService: TranslationService
    @StateObject private var arViewModel = ARViewModel()
    
    @State private var showNoLanguagesAlert = false

    enum Tab {
        case arTranslationView
        case savedWordsView
        case settingsView
    }
    
    @State private var selectedTab: Tab = .settingsView

    var body: some View {
        TabView(selection: $selectedTab) {
            ARTranslationView(arViewModel: arViewModel)
                .tabItem {
                    Label("Translate", systemImage: "camera.viewfinder")
                }
                .tag(Tab.arTranslationView)
            
            SavedWords()
                .tabItem {
                    Label("Saved Words", systemImage: "bookmark.fill")
                }
                .tag(Tab.savedWordsView)
                
            SettingsTabView(arViewModel: arViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settingsView)
        }
        .withCoreDataErrorHandling()
        .onReceive(translationService.$availableLanguages) { languages in
            if !languages.isEmpty {
                arViewModel.updateSelectedLanguageFromUserDefaults(availableLanguages: languages)
                showNoLanguagesAlert = false
            } else if !translationService.isInitialLoading {
                showNoLanguagesAlert = true
            }
        }
        .alert("No Languages Available", isPresented: $showNoLanguagesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No translation languages are currently available. This may be due to network connectivity issues or Apple's translation service not being available. Please try again later or check if device translation services are enabled in Settings.")
        }
    }
}

#Preview {
    let translationService = TranslationService()
    translationService.availableLanguages = [
        AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: Locale.Language(languageCode: "de", region: "DE"))
    ]
    
    return ContentView()
        .environmentObject(translationService)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

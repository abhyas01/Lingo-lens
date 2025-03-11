//
//  ContentView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var arViewModel = ARViewModel()

    enum Tab {
        case arTranslationView
        case savedWordsView
        case settingsView
    }
    
    @State private var selectedTab: Tab = .arTranslationView

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

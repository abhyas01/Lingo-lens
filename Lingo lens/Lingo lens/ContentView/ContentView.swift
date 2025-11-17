//
//  ContentView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

/// Main container view that manages navigation between app sections through tabs
struct ContentView: View {

    // MARK: - Properties

    // Provides translation features throughout the app
    @EnvironmentObject var translationService: TranslationService
    
    // Manages AR camera session and translation-related state
    @StateObject private var arViewModel = ARViewModel()
    
    // Controls alert when no languages are available for translation
    @State private var showNoLanguagesAlert = false

    // Navigation tabs for the app's main sections
    enum Tab {
        case arTranslationView
        case translatorView
        case conversationView
        case savedWordsView
        case settingsView
    }

    // Currently selected tab in the UI
    @State private var selectedTab: Tab = .arTranslationView

    // MARK: - View Body

    var body: some View {
        TabView(selection: $selectedTab) {
            ARTranslationView(arViewModel: arViewModel)
                .tabItem {
                    Label("AR Translate", systemImage: "camera.viewfinder")
                }
                .tag(Tab.arTranslationView)

            TranslatorView(translationService: translationService)
                .tabItem {
                    Label("Translator", systemImage: "character.bubble")
                }
                .tag(Tab.translatorView)

            ConversationListenerView(translationService: translationService)
                .tabItem {
                    Label("Conversation", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(Tab.conversationView)

            SavedWords()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(Tab.savedWordsView)

            SettingsTabView(arViewModel: arViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settingsView)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .withCoreDataErrorHandling()
        
        .onReceive(translationService.$availableLanguages) { languages in
            print("🌐 Available languages updated: \(languages.count) languages available")
            if !languages.isEmpty {
                arViewModel.updateSelectedLanguageFromUserDefaults(availableLanguages: languages)
                showNoLanguagesAlert = false
            } else if !translationService.isInitialLoading {
                print("⚠️ No languages available - showing alert")
                showNoLanguagesAlert = true
            }
        }
        
        .alert("No Languages Available", isPresented: $showNoLanguagesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No translation languages are currently available. This may be due to network connectivity issues or Apple's translation service not being available. Please try again later or check if device translation services are enabled in Settings.")
        }
        
        .onChange(of: selectedTab) { oldValue, newValue in
            print("📑 Tab changed from \(oldValue) to \(newValue)")
            if newValue == .arTranslationView || newValue == .translatorView ||
               newValue == .conversationView || newValue == .savedWordsView {
                Task {
                    print("🔊 Preparing audio session for tab: \(newValue)")
                    SpeechManager.shared.prepareAudioSession()
                }
            } else if newValue == .settingsView {
                print("🔇 Deactivating audio session for settings tab")
                SpeechManager.shared.deactivateAudioSession()
            }
        }

        .onAppear {
            if selectedTab == .arTranslationView || selectedTab == .translatorView ||
               selectedTab == .conversationView || selectedTab == .savedWordsView {
                Task {
                    SpeechManager.shared.prepareAudioSession()
                }
            }
        }

        // When app becomes active again from background
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in

            // Prepare audio session if we're on a tab that needs it
            if selectedTab == .arTranslationView || selectedTab == .translatorView ||
               selectedTab == .conversationView || selectedTab == .savedWordsView {
                Task {
                    SpeechManager.shared.prepareAudioSession()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    let translationService = TranslationService()
    translationService.availableLanguages = [
        AvailableLanguage(locale: .init(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: .init(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: .init(languageCode: "de", region: "DE"))
    ]
    
    return ContentView()
        .environmentObject(translationService)
        .environmentObject(AppearanceManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Active Detection") {
    let translationService = TranslationService()
    let arViewModel = ARViewModel()
    arViewModel.isDetectionActive = true
    arViewModel.detectedObjectName = "Coffee Cup"
    arViewModel.adjustableROI = CGRect(x: 100, y: 100, width: 200, height: 200)
    
    return ContentView()
        .environmentObject(translationService)
        .environmentObject(AppearanceManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

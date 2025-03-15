//
//  Lingo_lensApp.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

@main
struct Lingo_lensApp: App {

    // Add logging on app startup
    init() {
        print("🚀 App initializing...")
    }
    
    // MARK: - Properties

    // Track whether to show onboarding
    @State private var showOnboarding = true
    
    // Provides translation features throughout the app
    @StateObject private var translationService = TranslationService()
    
    // Handles app theme (dark mode, light mode) settings
    @StateObject private var appearanceManager = AppearanceManager()

    // Manages saved translations in Core Data
    let persistenceController = PersistenceController.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            
            // Show onboarding
            if showOnboarding {
                
                OnboardingView {
                    showOnboarding = false
                }
                .preferredColorScheme(appearanceManager.colorSchemeOption.colorScheme)
                
            } else {
                
                ContentView()
                
                    // Log app lifecycle events
                    .onAppear {
                        print("📱 App appeared - Main UI loaded")
                    }
                
                    // Makes translation service available to all child views
                    .environmentObject(translationService)
                
                    // Makes appearance settings available to all child views
                    .environmentObject(appearanceManager)
                
                    // Applies the user's selected color scheme
                    .preferredColorScheme(appearanceManager.colorSchemeOption.colorScheme)
                
                    // Gives Core Data access to all views
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
                    // Save data when app is terminated
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                        print("🛑 App terminating - Saving context")
                        persistenceController.saveContext()
                        SpeechManager.shared.deactivateAudioSession()
                    }
                
                    // Save data when app goes to background
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        print("⏱️ App entering background - Saving context")
                        persistenceController.saveContext()
                        SpeechManager.shared.deactivateAudioSession()
                    }
            }
        }
    }
}

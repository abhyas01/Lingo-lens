//
//  Lingo_lensApp.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

@main
struct Lingo_lensApp: App {
    
    init() {
        //  If app was not initialized already, only then we call
        //  DataManager.shared.trackAppLaunch() to increment the
        //  launch count
        if !Self.didInitOnce {
            Self.didInitOnce = true

            Logger.info("App initializing...")

            // Track the app launch only the first time this
            // SwiftUI app struct is created in a truly fresh run
            DataManager.shared.trackAppLaunch()
        }
    }
    
    // MARK: - Properties

    //  Track if the app initialized
    private static var didInitOnce = false
    
    // Track whether to show onboarding
    @State private var showOnboarding = !DataManager.shared.didFinishOnBoarding

    // Add state for showing splash screen
    @State private var showSplashScreen = true
    
    // Provides translation features throughout the app
    @StateObject private var translationService = TranslationService()
    
    // Handles app theme (dark mode, light mode) settings
    @StateObject private var appearanceManager = AppearanceManager()

    // Manages saved translations in Core Data
    let persistenceController = PersistenceController.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            
            ZStack {
                
                Group {
                    
                    // Show onboarding
                    if showOnboarding {
                        
                        OnboardingView {
                            showOnboarding = false
                            DataManager.shared.finishOnBoarding()
                        }
                        .preferredColorScheme(appearanceManager.colorSchemeOption.colorScheme)
                        
                    } else {
                        
                        ContentView()

                            // Log app lifecycle events
                            .onAppear {
                                Logger.info("Main UI loaded")
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
                                Logger.info("App terminating - Saving context")
                                persistenceController.saveContext()
                                SpeechManager.shared.deactivateAudioSession()
                            }

                            // Save data when app goes to background
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                                Logger.info("App entering background - Saving context")
                                persistenceController.saveContext()
                                SpeechManager.shared.deactivateAudioSession()
                            }
                    }
                }
                
                // Show Splash Screen
                if showSplashScreen {
                    
                    SplashScreen()
                        .ignoresSafeArea()
                        .zIndex(1)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.linear(duration: 0)),
                            removal: .opacity.animation(.easeOut(duration: 0.3))
                        ))
                        .onAppear {
                            
                            // Dismiss splash after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + AppLaunchConstants.splashScreenDuration) {
                                showSplashScreen = false
                            }
                        }
                }
            }
        }
    }
}

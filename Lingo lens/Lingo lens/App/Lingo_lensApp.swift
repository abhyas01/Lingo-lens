//
//  Lingo_lensApp.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

@main
struct Lingo_lensApp: App {
    @StateObject private var translationService = TranslationService()
    @StateObject private var appearanceManager = AppearanceManager()

    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(translationService)
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.colorSchemeOption.colorScheme)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    persistenceController.saveContext()
                    SpeechManager.shared.deactivateAudioSession()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    persistenceController.saveContext()
                    SpeechManager.shared.deactivateAudioSession()
                }
        }
    }
}

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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(translationService)
        }
    }
}

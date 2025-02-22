//
//  TranslationManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//


import Foundation

class TranslationManager {
    static let shared = TranslationManager()
    
    func translate(_ text: String, to targetLanguage: Language, completion: @escaping (String?) -> Void) {
        // Here you would implement the Apple Translate API
        // For now, we'll simulate the translation
        let translatedText = "[\(targetLanguage.name)] " + text
        completion(translatedText)
    }
}

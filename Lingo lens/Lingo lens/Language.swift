//
//  Language.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/21/25.
//


import Foundation

struct Language: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    
    static let supportedLanguages = [
        Language(code: "es", name: "Spanish"),
        Language(code: "fr", name: "French"),
        Language(code: "de", name: "German"),
        Language(code: "it", name: "Italian"),
        Language(code: "pt", name: "Portuguese"),
        Language(code: "ru", name: "Russian"),
        Language(code: "zh", name: "Chinese"),
        Language(code: "ar", name: "Arabic"),
        Language(code: "ko", name: "Korean"),
        Language(code: "ja", name: "Japanese")
    ]
}

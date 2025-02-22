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
        Language(code: "es-ES", name: "Spanish"),
        Language(code: "fr-FR", name: "French"),
        Language(code: "de-DE", name: "German"),
        Language(code: "it-IT", name: "Italian"),
        Language(code: "pt-PT", name: "Portuguese"),
        Language(code: "ru-RU", name: "Russian"),
        Language(code: "zh-Hans", name: "Chinese (Simplified)"),
        Language(code: "ar-SA", name: "Arabic"),
        Language(code: "ko-KR", name: "Korean"),
        Language(code: "ja-JP", name: "Japanese")
    ]
}

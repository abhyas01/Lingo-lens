//
//  Locale+Extensions.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation

extension Locale.Language {
    /// Returns a user-friendly display name for the language
    var displayName: String {
        Locale.current.localizedString(forIdentifier: self.minimalIdentifier) ?? self.minimalIdentifier
    }

    /// Returns the language code (e.g., "en", "es", "fr")
    var code: String {
        self.minimalIdentifier
    }

    /// Common languages for quick access
    static let english = Locale.Language(identifier: "en")
    static let spanish = Locale.Language(identifier: "es")
    static let french = Locale.Language(identifier: "fr")
    static let german = Locale.Language(identifier: "de")
    static let italian = Locale.Language(identifier: "it")
    static let portuguese = Locale.Language(identifier: "pt")
    static let russian = Locale.Language(identifier: "ru")
    static let japanese = Locale.Language(identifier: "ja")
    static let korean = Locale.Language(identifier: "ko")
    static let chinese = Locale.Language(identifier: "zh")
    static let arabic = Locale.Language(identifier: "ar")
    static let hindi = Locale.Language(identifier: "hi")
}

extension Locale {
    /// Gets available languages for translation
    static var availableTranslationLanguages: [Locale.Language] {
        Locale.availableIdentifiers
            .map { Locale.Language(identifier: $0) }
            .filter { $0.minimalIdentifier.count == 2 || $0.minimalIdentifier.count == 5 }
            .sorted { lang1, lang2 in
                lang1.displayName < lang2.displayName
            }
    }
}

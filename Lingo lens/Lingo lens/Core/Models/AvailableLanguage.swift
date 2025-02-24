//
//  AvailableLanguage.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import Foundation

/// Model representing supported language for translation
struct AvailableLanguage: Identifiable, Hashable, Comparable {
    var id: Self { self }
    let locale: Locale.Language

    /// Returns localized name of the language with its language code
    func localizedName() -> String {
        let currentLocale = Locale.current
        let short = shortName()
        guard let name = currentLocale.localizedString(forLanguageCode: short) else {
            return "Unknown language code"
        }
        return "\(name) (\(short))"
    }

    /// Returns the language code in format "languageCode-region"
    func shortName() -> String {
        "\(locale.languageCode ?? "")-\(locale.region ?? "")"
    }

    /// Comparable Implementation
    static func <(lhs: AvailableLanguage, rhs: AvailableLanguage) -> Bool {
        return lhs.localizedName() < rhs.localizedName()
    }
}

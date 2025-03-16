//
//  AvailableLanguage.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import Foundation

/// Model representing supported language for translation
/// Wraps the system Locale.Language with helper functions
struct AvailableLanguage: Identifiable, Hashable, Comparable {
    
    // Use self as the ID for SwiftUI lists
    var id: Self { self }
    
    // The underlying locale that contains language/region data
    let locale: Locale.Language

    /// Returns localized name of the language with its language code
    /// For example: "Spanish (es-ES)" or "German (de-DE)"
    func localizedName() -> String {
        let currentLocale = Locale.current
        let short = shortName()
        
        // Get the language name in the user's current locale
        guard let name = currentLocale.localizedString(forLanguageCode: short) else {
            return "Unknown language code"
        }
        
        // Format as "Language (code)"
        return "\(name) (\(short))"
    }

    /// Returns the language code in format "languageCode-region"
    /// For example: "en-US" or "es-ES"
    func shortName() -> String {
        "\(locale.languageCode ?? "")-\(locale.region ?? "")"
    }

    /// Comparable Implementation
    /// Sorts languages alphabetically by their localized name
    static func <(lhs: AvailableLanguage, rhs: AvailableLanguage) -> Bool {
        return lhs.localizedName() < rhs.localizedName()
    }
}

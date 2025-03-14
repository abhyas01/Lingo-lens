//
//  LanguageFilter.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import Foundation

/// Model for languages in saved translations filter menu
/// Used in the Saved Words tab for filtering by language
struct LanguageFilter: Identifiable, Hashable, Comparable {
    
    // Unique ID for SwiftUI lists
    let id = UUID()
    
    // Language code like "en-US" or "es-ES"
    let languageCode: String
    
    // Display name like "English (en-US)" or "Spanish (es-ES)"
    let languageName: String
    
    /// Converts language code to flag emoji
    /// For example, "en-US" becomes 🇺🇸
    var flag: String {
        languageCode.toFlagEmoji()
    }
    
    // MARK: - Protocol Implementations

    /// Hashable implementation for dictionary keys and sets
    func hash(into hasher: inout Hasher) {
        hasher.combine(languageCode)
    }
    
    /// Equatable implementation for comparing language filters
    /// Two filters are equal if they have the same language code
    static func == (lhs: LanguageFilter, rhs: LanguageFilter) -> Bool {
        return lhs.languageCode == rhs.languageCode
    }
    
    /// Comparable implementation for sorting languages
    /// Orders languages alphabetically by name
    static func < (lhs: LanguageFilter, rhs: LanguageFilter) -> Bool {
        return lhs.languageName < rhs.languageName
    }
    
    /// Creates a language filter from Core Data dictionary result
    /// Used when loading language filters from saved translations
    static func fromDictionary(_ dict: [String: Any]) -> LanguageFilter? {
        guard let code = dict["languageCode"] as? String,
              let name = dict["languageName"] as? String else {
            return nil
        }
        
        return LanguageFilter(
            languageCode: code,
            languageName: name
        )
    }
}

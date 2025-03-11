//
//  LanguageFilter.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import Foundation

/// Model for language filtering in saved translations
struct LanguageFilter: Identifiable, Hashable, Comparable {
    let id = UUID()
    let languageCode: String
    let languageName: String
    
    /// Flag emoji representing the language's region
    var flag: String {
        languageCode.toFlagEmoji()
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(languageCode)
    }
    
    // Equatable implementation
    static func == (lhs: LanguageFilter, rhs: LanguageFilter) -> Bool {
        return lhs.languageCode == rhs.languageCode
    }
    
    // Comparable implementation
    static func < (lhs: LanguageFilter, rhs: LanguageFilter) -> Bool {
        return lhs.languageName < rhs.languageName
    }
    
    /// Creates a language filter from Core Data dictionary result
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

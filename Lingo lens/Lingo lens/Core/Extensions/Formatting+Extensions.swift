//
//  Formatting+Extensions.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import Foundation

// MARK: - String Extensions
extension String {
    /// Converts a language code to its corresponding flag emoji
    func toFlagEmoji() -> String {
        guard let regionCode = self.split(separator: "-").last else {
            return "🌐"
        }
        
        let base: UInt32 = 127397
        var emoji = ""
        
        for scalar in regionCode.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(Character(flagScalar))
            }
        }
        
        return emoji.isEmpty ? "🌐" : emoji
    }
}

// MARK: - Date Extensions
extension Date {
    /// Formats date with short date style (no time)
    func toShortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Formats date with medium date style and short time
    func toMediumDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

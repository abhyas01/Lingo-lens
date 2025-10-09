//
//  Formatting+Extensions.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//

import Foundation

// MARK: - String Extensions

extension String {
    
    /// Converts a language code like "en-US" to its corresponding flag emoji 🇺🇸
    func toFlagEmoji() -> String {
        
        // Try to extract the region code (like "US" from "en-US")
        guard let regionCode = self.split(separator: "-").last else {
            return "🌐"
        }
        
        // Unicode math: convert region code letters to corresponding flag emoji
        // Each country code letter (like U, S) gets shifted to the regional indicator symbol
        let base: UInt32 = 127397
        var emoji = ""
        
        for scalar in regionCode.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(Character(flagScalar))
            }
        }
        
        // Return globe emoji as fallback if conversion failed
        return emoji.isEmpty ? "🌐" : emoji
    }
}

// MARK: - Date Extensions

extension Date {
    
    /// Creates a short date string like "3/11/25" without time
    func toShortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Creates a more detailed date and time like "Mar 11, 2025, 2:30 PM"
    func toMediumDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

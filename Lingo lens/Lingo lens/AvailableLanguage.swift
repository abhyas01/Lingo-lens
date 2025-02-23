//
//  AvailableLanguage.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import Foundation

struct AvailableLanguage: Identifiable, Hashable, Comparable {
    var id: Self { self }
    let locale: Locale.Language

    func localizedName() -> String {
        let currentLocale = Locale.current
        let short = shortName()
        guard let name = currentLocale.localizedString(forLanguageCode: short) else {
            return "Unknown language code"
        }
        return "\(name) (\(short))"
    }

    func shortName() -> String {
        "\(locale.languageCode ?? "")-\(locale.region ?? "")"
    }

    static func <(lhs: AvailableLanguage, rhs: AvailableLanguage) -> Bool {
        return lhs.localizedName() < rhs.localizedName()
    }
}

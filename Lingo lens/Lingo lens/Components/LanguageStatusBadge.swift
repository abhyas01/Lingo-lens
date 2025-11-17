//
//  LanguageStatusBadge.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Badge showing whether a language is available offline
struct LanguageStatusBadge: View {

    // MARK: - Constants

    private static let compactFontSize: CGFloat = 10
    private static let standardFontSize: CGFloat = 12

    // MARK: - Nested Types

    enum Status {
        case downloaded
        case needsDownload
        case downloading
        case checking

        var color: Color {
            switch self {
            case .downloaded: return .green
            case .needsDownload: return .orange
            case .downloading: return .blue
            case .checking: return .gray
            }
        }

        var icon: String {
            switch self {
            case .downloaded: return "checkmark.circle.fill"
            case .needsDownload: return "icloud.and.arrow.down"
            case .downloading: return "arrow.down.circle"
            case .checking: return "clock"
            }
        }

        var text: String {
            switch self {
            case .downloaded: return "Offline"
            case .needsDownload: return "Download"
            case .downloading: return "Downloading"
            case .checking: return "Checking"
            }
        }
    }

    let status: Status
    let compact: Bool

    init(status: Status, compact: Bool = false) {
        self.status = status
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: compact ? Self.compactFontSize : Self.standardFontSize))

            if !compact {
                Text(status.text)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(status.color.opacity(0.8))
        .cornerRadius(compact ? 4 : 6)
    }
}

#Preview("Downloaded") {
    LanguageStatusBadge(status: .downloaded)
        .padding()
        .background(Color.gray)
}

#Preview("Needs Download") {
    LanguageStatusBadge(status: .needsDownload)
        .padding()
        .background(Color.gray)
}

#Preview("Downloading") {
    LanguageStatusBadge(status: .downloading)
        .padding()
        .background(Color.gray)
}

#Preview("Compact") {
    HStack {
        LanguageStatusBadge(status: .downloaded, compact: true)
        LanguageStatusBadge(status: .needsDownload, compact: true)
        LanguageStatusBadge(status: .downloading, compact: true)
    }
    .padding()
    .background(Color.gray)
}

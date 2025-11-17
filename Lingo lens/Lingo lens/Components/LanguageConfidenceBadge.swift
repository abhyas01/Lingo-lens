//
//  LanguageConfidenceBadge.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Badge showing language detection confidence
struct LanguageConfidenceBadge: View {

    let confidence: Double  // 0.0 to 1.0
    let languageName: String

    private var confidencePercent: Int {
        Int(confidence * 100)
    }

    private var confidenceColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .yellow
        } else {
            return .orange
        }
    }

    private var confidenceIcon: String {
        if confidence >= 0.8 {
            return "checkmark.seal.fill"
        } else if confidence >= 0.6 {
            return "checkmark.seal"
        } else {
            return "exclamationmark.triangle"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.system(size: 10))

            Text("\(languageName) \(confidencePercent)%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.8))
        .cornerRadius(6)
    }
}

#Preview("High Confidence") {
    LanguageConfidenceBadge(confidence: 0.95, languageName: "Spanish")
        .padding()
        .background(Color.gray)
}

#Preview("Medium Confidence") {
    LanguageConfidenceBadge(confidence: 0.65, languageName: "French")
        .padding()
        .background(Color.gray)
}

#Preview("Low Confidence") {
    LanguageConfidenceBadge(confidence: 0.45, languageName: "German")
        .padding()
        .background(Color.gray)
}

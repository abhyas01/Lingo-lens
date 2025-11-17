//
//  RecognizedTextItem.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation
import CoreGraphics
import SceneKit

/// Represents a detected text item from OCR
struct RecognizedTextItem: Identifiable {
    var id = UUID()
    var text: String
    var confidence: Float
    var boundingBox: CGRect          // Normalized coordinates (0-1)
    var worldPosition: SCNVector3?   // AR anchor position
    var translatedText: String?
    var isSelected: Bool = false

    /// Color based on confidence level
    var confidenceColor: CGColor {
        if confidence >= 0.8 {
            return CGColor(red: 0, green: 1, blue: 0, alpha: 0.3)  // Green
        } else if confidence >= 0.5 {
            return CGColor(red: 1, green: 1, blue: 0, alpha: 0.3)  // Yellow
        } else {
            return CGColor(red: 1, green: 0, blue: 0, alpha: 0.3)  // Red
        }
    }

    /// Returns true if the text meets the minimum confidence threshold
    var meetsConfidenceThreshold: Bool {
        confidence >= 0.5
    }
}

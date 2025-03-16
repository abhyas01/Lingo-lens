//
//  DetectionLabel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

/// Displays the currently detected object name or guidance text
/// Shows red background when no object detected, green when object found
struct DetectionLabel: View {
    
    // The name of the currently detected object (empty string if none)
    let detectedObjectName: String
    
    var body: some View {
        
        // Text to display - either the object name or a guidance message
        let labelText = detectedObjectName.isEmpty ?
            "Couldn't detect. Keep moving / Fit object in box / Move closer." :
            detectedObjectName
        
        // Background color - red for no detection, green for successful detection
        let labelBackground = detectedObjectName.isEmpty ?
            Color.red.opacity(0.8) :
            Color.green.opacity(0.8)
        
        // The actual label with dynamic text and background
        Text(labelText)
            .font(.title3)
            .fontWeight(.medium)
            .padding(8)
            .background(labelBackground)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .accessibilityLabel("Detection Status")
            .accessibilityValue(detectedObjectName.isEmpty ?
                "No object detected" :
                "Detected object: \(detectedObjectName)")
    }
}

#Preview {
    VStack(spacing: 20) {
        DetectionLabel(detectedObjectName: "")
        
        DetectionLabel(detectedObjectName: "Coffee Cup")
        
        DetectionLabel(detectedObjectName: "Large Professional Camera with Telephoto Lens")
    }
    .padding()
    
}

//
//  DetectionLabel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

struct DetectionLabel: View {
    let detectedObjectName: String
    
    var body: some View {
        let labelText = detectedObjectName.isEmpty ?
            "Couldn't detect. Keep moving / Fit object in box / Move closer." :
            detectedObjectName
        
        let labelBackground = detectedObjectName.isEmpty ?
            Color.red.opacity(0.8) :
            Color.green.opacity(0.8)
        
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

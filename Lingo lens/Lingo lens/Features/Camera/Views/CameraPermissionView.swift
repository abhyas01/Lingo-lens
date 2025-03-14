//
//  CameraPermissionView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/23/25.
//

import SwiftUI

/// View displayed when camera permission is needed
/// Guides users to enable camera access with visual instructions
struct CameraPermissionView: View {
    
    // Actions passed from parent view
    let openSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Camera icon at the top
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 16)
                .accessibilityHidden(true)
            
            // Header and explanation text section
            VStack(spacing: 16) {
                Text("Camera Access Required")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Lingo Lens needs camera access to help you learn languages through object recognition. Please enable camera access in Settings to start your learning journey.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .accessibilityLabel("Camera access is required for object detection and translation")
            }
            
            // Action buttons section
            VStack(spacing: 12) {
                
                // Main settings button
                Button(action: openSettings) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .accessibilityHint("Opens iOS Settings to enable camera access")
                .padding(.horizontal, 32)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    CameraPermissionView(
        openSettings: {}
    )
}

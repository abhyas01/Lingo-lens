//
//  CameraPermissionView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/23/25.
//

import SwiftUI

struct CameraPermissionView: View {
    let openSettings: () -> Void
    let recheckPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 16)
            
            
            VStack(spacing: 16) {
                Text("Camera Access Required")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("Lingo Lens needs camera access to help you learn languages through object recognition. Please enable camera access in Settings to start your learning journey.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
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
                .padding(.horizontal, 32)
                
                Button(action: recheckPermission) {
                    Text("Check Again")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    CameraPermissionView(
        openSettings: {},
        recheckPermission: {}
    )
}

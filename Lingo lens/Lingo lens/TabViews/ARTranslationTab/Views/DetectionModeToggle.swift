//
//  DetectionModeToggle.swift
//  Lingo lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Toggle control for switching between object and text detection modes
struct DetectionModeToggle: View {

    @ObservedObject var arViewModel: ARViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Mode label
            Text(arViewModel.detectionMode == .objects ? "Object Detection" : "Text Recognition")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)

            // Toggle segmented control
            Picker("Detection Mode", selection: $arViewModel.detectionMode) {
                HStack(spacing: 4) {
                    Image(systemName: "cube")
                    Text("Objects")
                }
                .tag(ARViewModel.DetectionMode.objects)

                HStack(spacing: 4) {
                    Image(systemName: "textformat")
                    Text("Text")
                }
                .tag(ARViewModel.DetectionMode.text)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
            .onChange(of: arViewModel.detectionMode) { oldMode, newMode in
                // Clear overlays when switching modes
                if newMode == .text {
                    arViewModel.detectedObjectName = ""
                    arViewModel.clearTextOverlays()
                } else {
                    arViewModel.clearTextOverlays()
                }

                // Disable detection when switching
                arViewModel.isDetectionActive = false

                print("🔄 Switched detection mode from \(oldMode) to \(newMode)")
            }
        }
        .padding()
    }
}

#Preview {
    DetectionModeToggle(arViewModel: ARViewModel())
        .background(Color.gray)
}

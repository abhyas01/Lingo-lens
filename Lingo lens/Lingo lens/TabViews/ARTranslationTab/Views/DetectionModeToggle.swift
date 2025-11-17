//
//  DetectionModeToggle.swift
//  Lingo lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Toggle control for switching between object and text detection modes
struct DetectionModeToggle: View {

    // MARK: - Constants

    private static let labelPaddingHorizontal: CGFloat = 12
    private static let labelPaddingVertical: CGFloat = 4
    private static let segmentedMaxWidth: CGFloat = 200
    private static let togglePaddingHorizontal: CGFloat = 12
    private static let togglePaddingVertical: CGFloat = 6

    // MARK: - Properties

    @ObservedObject var arViewModel: ARViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Mode label
            Text(arViewModel.detectionMode == .objects ? "Object Detection" : "Text Recognition")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, Self.labelPaddingHorizontal)
                .padding(.vertical, Self.labelPaddingVertical)
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
            .frame(maxWidth: Self.segmentedMaxWidth)
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

                // Haptic feedback
                HapticManager.shared.modeChange()

                print("🔄 Switched detection mode from \(oldMode) to \(newMode)")
            }

            // Instant OCR toggle (only shown in text mode)
            if arViewModel.detectionMode == .text {
                HStack(spacing: 6) {
                    Image(systemName: arViewModel.instantOCRMode ? "viewfinder" : "viewfinder.circle")
                        .font(.caption)
                        .foregroundColor(.white)

                    Toggle("Instant OCR", isOn: $arViewModel.instantOCRMode)
                        .font(.caption)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .labelsHidden()

                    Text("Instant OCR")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Self.togglePaddingHorizontal)
                .padding(.vertical, Self.togglePaddingVertical)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .onChange(of: arViewModel.instantOCRMode) { oldValue, newValue in
                    // Haptic feedback
                    HapticManager.shared.toggle()

                    // Auto-start detection in instant mode
                    if newValue {
                        arViewModel.isDetectionActive = true
                        print("✨ Instant OCR enabled - auto-starting detection")
                    } else {
                        arViewModel.isDetectionActive = false
                        arViewModel.clearTextOverlays()
                        print("📦 Instant OCR disabled - switching to box mode")
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    DetectionModeToggle(arViewModel: ARViewModel())
        .background(Color.gray)
}

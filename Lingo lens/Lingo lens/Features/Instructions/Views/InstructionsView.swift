//
//  InstructionsView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/23/25.
//


import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                HStack {
                    Text("How to Use Lingo Lens")
                        .font(.title.bold())
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 20) {
                    instructionCard(
                        icon: "globe",
                        title: "1. Select Language",
                        description: "Open settings from the gear icon (bottom-left) and choose your target language under language selection. Hit done to confirm."
                    )
                    
                    instructionCard(
                        icon: "camera.viewfinder",
                        title: "2. Start Detection",
                        description: "Tap the green 'Start Detection' button in the bottom-center. Point your device at objects you want to identify."
                    )
                    
                    instructionCard(
                        icon: "square.dashed",
                        title: "3. Adjust Bounding Box",
                        description: "Fit objects inside the yellow box. Move the box by dragging edges or the icons on edges. Resize using corner circles. Move closer to object if needed."
                    )
                    
                    instructionCard(
                        icon: "plus.circle.fill",
                        title: "4. Add Annotations",
                        description: "When an object is detected (green text appears), tap the blue plus button on the bottom-right to place an annotation on an object."
                    )
                    
                    instructionCard(
                        icon: "hand.tap.fill",
                        title: "5. View Translations",
                        description: "Tap any annotation to see its translation and hear pronunciation in your selected language."
                    )
                    
                    instructionCard(
                        icon: "slider.horizontal.3",
                        title: "Additional Features",
                        description: "• Adjust annotation size with the slider in settings\n• Clear all annotations using the red button in settings\n• Stop detection mode when done exploring"
                    )
                }
                
                VStack(spacing: 16) {
                    Text("Enjoy Learning!")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                    
                    Text("Discover new languages with Lingo Lens")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func instructionCard(icon: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.title3.bold())
            }
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    InstructionsView()
}

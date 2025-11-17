//
//  SettingsPanel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

/// Panel that shows settings options in the AR view
/// Slides up from bottom when settings button is tapped
struct SettingsPanel: View {
    @ObservedObject var arViewModel: ARViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                
                // Header with title and close button
                HStack {
                    Text("Label Settings")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: {
                        Logger.debug("👆 Button pressed: Close settings panel")
                        settingsViewModel.toggleExpanded()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.primary)
                            .font(.system(size: 20))
                    }
                }
                .padding(.bottom)
                
                // Main settings options
                VStack(alignment: .leading, spacing: 16) {
                    annotationSizeSection
                    clearAnnotationsButton
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(15)
            .frame(width: 300)
            
            // Position panel at bottom of screen
            .position(
                x: 165,
                y: geometry.size.height - geometry.safeAreaInsets.bottom - 100
            )
            
            // Smooth slide-up animation
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(x: 0, y: 50)),
                removal: .opacity.combined(with: .offset(x: 0, y: 50))
            ))
        }
    }
    
    // Slider to adjust annotation size
    private var annotationSizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label Size")
                .foregroundStyle(.primary)

            // Slider that directly updates annotation scale in view model
            Slider(value: $arViewModel.annotationScale,
                   in: 0.2...5.0,
                   step: 0.1)
            .accessibilityLabel("Label Size")
            .accessibilityValue("\(Int(arViewModel.annotationScale * 100))% of default size")
            .accessibilityHint("Adjust to make labels larger or smaller")
            .tint(.accentColor)
        }
    }
    
    // Button to remove all placed annotations
    private var clearAnnotationsButton: some View {
        Button(action: {
            Logger.debug("👆 Button pressed: Clear all labels")
            arViewModel.resetAnnotations()
        }) {
            HStack {
                Image(systemName: "trash")
                Text("Clear all labels")
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
        }
        .accessibilityLabel("Clear all labels")
        .accessibilityHint("Removes all translation labels from the screen")
    }
}

#Preview {
    let arViewModel = ARViewModel()
    let settingsViewModel = SettingsViewModel()
    
    arViewModel.selectedLanguage = AvailableLanguage(
        locale: Locale.Language(languageCode: "es", region: "ES")
    )
    arViewModel.annotationScale = 1.0
    settingsViewModel.isExpanded = true
    
    return ZStack {
        
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        SettingsPanel(
            arViewModel: arViewModel,
            settingsViewModel: settingsViewModel
        )
    }
}

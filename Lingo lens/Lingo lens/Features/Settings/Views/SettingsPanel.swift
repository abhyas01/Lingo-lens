//
//  SettingsPanel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

struct SettingsPanel: View {
    @ObservedObject var arViewModel: ARViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    settingsViewModel.toggleExpanded()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 16) {
                languageSelectionSection
                annotationSizeSection
                clearAnnotationsButton
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .frame(width: 300)
        .position(x: 160, y: UIScreen.main.bounds.height - 200)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(x: 0, y: 50)),
            removal: .opacity.combined(with: .offset(x: 0, y: 50))
        ))
    }
    
    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Language")
                .foregroundColor(.white)
            
            Button(action: {
                settingsViewModel.showLanguageSelection = true
            }) {
                HStack {
                    Text(arViewModel.selectedLanguage.localizedName())
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(8)
            }
        }
    }
    
    private var annotationSizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Annotation Size")
                .foregroundColor(.white)
            
            Slider(value: $arViewModel.annotationScale,
                   in: 0.2...3.5,
                   step: 0.1)
        }
    }
    
    private var clearAnnotationsButton: some View {
        Button(action: {
            arViewModel.resetAnnotations()
        }) {
            HStack {
                Image(systemName: "trash")
                Text("Clear All Annotations")
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
        }
    }
}

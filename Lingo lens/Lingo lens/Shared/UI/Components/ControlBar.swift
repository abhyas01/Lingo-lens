//
//  ControlBar.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

struct ControlBar: View {
    @ObservedObject var arViewModel: ARViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        HStack {
            settingsButton
            Spacer()
            detectionToggleButton
            Spacer()
            addAnnotationButton
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            settingsViewModel.toggleExpanded()
            if settingsViewModel.isExpanded {
                arViewModel.isDetectionActive = false
                arViewModel.detectedObjectName = ""
            }
        }) {
            Image(systemName: "gear")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.gray.opacity(0.7))
                .clipShape(Circle())
        }
        .rotation3DEffect(
            .degrees(settingsViewModel.isExpanded ? 90 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .frame(width: 60)
        .padding(.leading)
    }
    
    private var detectionToggleButton: some View {
        Button(action: {
            arViewModel.isDetectionActive.toggle()
            if !arViewModel.isDetectionActive {
                arViewModel.detectedObjectName = ""
            }
        }) {
            Text(arViewModel.isDetectionActive ?
                 "Stop Detection" : "Start Detection")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .frame(minWidth: 140)
                .background(arViewModel.isDetectionActive ?
                          Color.red.opacity(0.8) : Color.green.opacity(0.8))
                .cornerRadius(12)
        }
    }
    
    private var addAnnotationButton: some View {
        Button(action: {
            guard !arViewModel.detectedObjectName.isEmpty else { return }
            arViewModel.addAnnotation()
        }) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(
                    arViewModel.detectedObjectName.isEmpty || !arViewModel.isDetectionActive ?
                    Color.gray.opacity(0.25) : Color.blue
                )
                .padding()
        }
        .disabled(arViewModel.detectedObjectName.isEmpty || !arViewModel.isDetectionActive)
        .frame(width: 60)
        .padding(.trailing)
    }
}

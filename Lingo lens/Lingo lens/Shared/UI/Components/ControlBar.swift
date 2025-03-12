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
    @EnvironmentObject private var translationService: TranslationService
    
    @State private var isCheckingLanguage = false
    @State private var showLanguageDownloadPrompt = false
    
    var body: some View {
        HStack {
            settingsButton
            Spacer()
            detectionToggleButton
            Spacer()
            addAnnotationButton
        }
        .sheet(isPresented: $showLanguageDownloadPrompt) {
            LanguageDownloadView(
                language: arViewModel.selectedLanguage,
                isPresented: $showLanguageDownloadPrompt,
                onDownloadComplete: {
                    startDetection()
                }
            )
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            withAnimation {
                settingsViewModel.toggleExpanded()
            }
            if settingsViewModel.isExpanded {
                arViewModel.isDetectionActive = false
                arViewModel.detectedObjectName = ""
            }
        }) {
            Image(systemName: "textformat.size")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .padding(16)
                .background(Color.gray.opacity(0.7))
                .clipShape(Circle())
                .opacity(settingsViewModel.isExpanded ? 0.3 : 1)
        }
        .accessibilityLabel("Label Settings")
        .accessibilityHint("Opens label settings panel to adjust label options")
        .frame(width: 60)
        .padding(.leading)
        .disabled(settingsViewModel.isExpanded)
    }
    
    private var detectionToggleButton: some View {
        Button(action: {
            if arViewModel.isDetectionActive {
                arViewModel.isDetectionActive = false
                arViewModel.detectedObjectName = ""
            } else {
                checkLanguageAndStartDetection()
            }
        }) {
            if isCheckingLanguage {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                    Text("Checking")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(12)
                .frame(minWidth: 140)
                .background(Color.orange.opacity(0.8))
                .cornerRadius(12)
            } else {
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
        .accessibilityLabel(arViewModel.isDetectionActive ? "Stop Object Detection" : "Start Object Detection")
        .accessibilityHint(arViewModel.isDetectionActive ?
            "Stop detecting objects in camera view" :
            "Begin detecting objects in camera view")
        .disabled(isCheckingLanguage)
    }
    
    private var addAnnotationButton: some View {
        ZStack {
            if arViewModel.isAddingAnnotation {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 60, height: 60)
                    
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(.white)
                }
                .padding()
            } else {
                Button(action: {
                    guard !arViewModel.detectedObjectName.isEmpty && !arViewModel.isAddingAnnotation else { return }
                    arViewModel.addAnnotation()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(
                            determineAddButtonColor()
                        )
                        .padding()
                }
                .disabled(arViewModel.detectedObjectName.isEmpty || !arViewModel.isDetectionActive)
            }
        }
        .frame(width: 60)
        .padding(.trailing)
        .accessibilityLabel(arViewModel.isAddingAnnotation ? "Adding Annotation" : "Add Annotation")
        .accessibilityHint(arViewModel.detectedObjectName.isEmpty ? "No object detected" :
                          arViewModel.isAddingAnnotation ? "Adding annotation in progress" :
                          "Adds a translation annotation for the detected object")
        .accessibilityValue(arViewModel.detectedObjectName.isEmpty ? "No object detected" :
                           "Ready to annotate \(arViewModel.detectedObjectName)")
    }

    private func determineAddButtonColor() -> Color {
        if arViewModel.isAddingAnnotation {
            return Color.gray
        } else if arViewModel.detectedObjectName.isEmpty || !arViewModel.isDetectionActive {
            return Color.gray.opacity(0.25)
        } else {
            return Color.blue
        }
    }
    
    private func checkLanguageAndStartDetection() {
        isCheckingLanguage = true
        
        Task {
            let isDownloaded = await translationService.isLanguageDownloaded(
                language: arViewModel.selectedLanguage
            )
            
            await MainActor.run {
                isCheckingLanguage = false
                
                if isDownloaded {
                    startDetection()
                } else {
                    showLanguageDownloadPrompt = true
                }
            }
        }
    }
    
    private func startDetection() {
        if let sceneView = arViewModel.sceneView {
            let boxSize: CGFloat = 200
            arViewModel.adjustableROI = CGRect(
                x: (sceneView.bounds.width - boxSize) / 2,
                y: (sceneView.bounds.height - boxSize) / 2,
                width: boxSize,
                height: boxSize
            )
        }
        arViewModel.isDetectionActive = true
    }
}

#Preview {
    let arViewModel = ARViewModel()
    let settingsViewModel = SettingsViewModel()
    
    return Group {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ControlBar(
                arViewModel: arViewModel,
                settingsViewModel: settingsViewModel
            )
        }
        
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ControlBar(
                arViewModel: arViewModel,
                settingsViewModel: settingsViewModel
            )
        }
        .onAppear {
            arViewModel.isDetectionActive = true
            arViewModel.detectedObjectName = "Coffee Cup"
        }
        
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ControlBar(
                arViewModel: arViewModel,
                settingsViewModel: settingsViewModel
            )
        }
        .onAppear {
            settingsViewModel.isExpanded = true
        }
        
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ControlBar(
                arViewModel: arViewModel,
                settingsViewModel: settingsViewModel
            )
        }
        .onAppear {
            arViewModel.isDetectionActive = true
            arViewModel.detectedObjectName = ""
        }
    }
}

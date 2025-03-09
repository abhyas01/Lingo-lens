//
//  ARView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import AVFoundation

struct ARTranslationView: View {
    @ObservedObject var arViewModel: ARViewModel
    
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    @State private var previousSize: CGSize = .zero
    @State private var showInstructions = false
    @State private var showInfoPopover = true
    @EnvironmentObject var translationService: TranslationService
    
    var isActiveTab: Bool

    var body: some View {
        Group {
            if cameraPermissionManager.showPermissionAlert {
                CameraPermissionView(
                    openSettings: {
                        cameraPermissionManager.openAppSettings()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            cameraPermissionManager.checkPermission()
                        }
                    },
                    recheckPermission: {
                        cameraPermissionManager.checkPermission()
                    }
                )
            } else {
                mainARView
            }
        }
        .onAppear(perform: cameraPermissionManager.checkPermission)
        .onChange(of: isActiveTab) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.async {
                    arViewModel.resetAnnotations()
                    arViewModel.resumeARSession()
                }
            } else {
                arViewModel.pauseARSession()
                arViewModel.resetAnnotations()
            }
        }
    }
    
    private var mainARView: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            if arViewModel.isDetectionActive {
                boundingBoxView
            }
            
            VStack {
                HStack {
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            arViewModel.isDetectionActive = false
                            arViewModel.detectedObjectName = ""
                            showInstructions = true
                            showInfoPopover = false
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.gray.opacity(0.7))
                                .clipShape(Circle())
                                .accessibilityLabel("Instructions")
                                .accessibilityHint("Learn how to use Lingo Lens")
                        }
                        
                        if showInfoPopover {
                            VStack(alignment: .trailing, spacing: 8) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.white)
                                        .padding(.trailing, 12)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.white)
                                        .clipShape(Circle())
                                    
                                    Text("Tap here to learn how to use the app")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .accessibilityAddTraits(.isStaticText)
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.7))
                                .cornerRadius(12)
                            }
                            .offset(y: 45)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut, value: showInfoPopover)
                        }
                    }
                }
                .padding()
                
                if arViewModel.showPlacementError {
                    Text(arViewModel.placementErrorMessage)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding()
                        .transition(.opacity)
                        .zIndex(1)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                
                if arViewModel.isDetectionActive {
                    DetectionLabel(detectedObjectName: arViewModel.detectedObjectName)
                }
                
                Spacer()
                
                ControlBar(
                    arViewModel: arViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
            
            if settingsViewModel.isExpanded {
                SettingsPanel(
                    arViewModel: arViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
        }
        
        .animation(.easeInOut, value: arViewModel.showPlacementError)
        
        .onChange(of: arViewModel.isDetectionActive) { _, isActive in
            if isActive {
                showInfoPopover = false
            }
        }
        
        .onChange(of: settingsViewModel.isExpanded) { _, isExpanded in
            if isExpanded {
                showInfoPopover = false
            }
        }
        
        .sheet(isPresented: $showInstructions) {
            InstructionsView()
        }
        
        .sheet(isPresented: $settingsViewModel.showLanguageSelection) {
            LanguageSelectionView(
                selectedLanguage: $arViewModel.selectedLanguage,
                isPresented: $settingsViewModel.showLanguageSelection
            )
            .environmentObject(translationService)
        }
        
        .sheet(isPresented: $arViewModel.isShowingAnnotationDetail) {
            if let originalText = arViewModel.selectedAnnotationText {
                AnnotationDetailView(
                    originalText: originalText,
                    targetLanguage: arViewModel.selectedLanguage
                )
                .environmentObject(translationService)
            }
        }
    }
    
    private var boundingBoxView: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    if arViewModel.adjustableROI == .zero {
                        let boxSize: CGFloat = 200
                        arViewModel.adjustableROI = CGRect(
                            x: (geo.size.width - boxSize) / 2,
                            y: (geo.size.height - boxSize) / 2,
                            width: boxSize,
                            height: boxSize
                        )
                    }
                    previousSize = geo.size
                }
                
                .onChange(of: geo.size) { oldSize, newSize in
                    guard newSize != previousSize else { return }
                    arViewModel.adjustableROI = arViewModel.adjustableROI
                        .resizedAndClamped(from: previousSize, to: newSize)
                    previousSize = newSize
                }
            
            AdjustableBoundingBox(
                roi: $arViewModel.adjustableROI,
                containerSize: geo.size
            )
        }
    }
}

struct ARTranslationView_Previews: PreviewProvider {
    static var previews: some View {
        
        let mockTranslationService = TranslationService()
        mockTranslationService.availableLanguages = [
            AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES")),
            AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR")),
            AvailableLanguage(locale: Locale.Language(languageCode: "de", region: "DE"))
        ]
        
        let arViewModel = ARViewModel()
        
        return Group {
            ARTranslationView(arViewModel: arViewModel, isActiveTab: true)
                .environmentObject(mockTranslationService)
                .previewDisplayName("Normal State")
            
            ARTranslationView(arViewModel: arViewModel, isActiveTab: true)
                .environmentObject(mockTranslationService)
                .onAppear {
                    let viewModel = ARViewModel()
                    viewModel.isDetectionActive = true
                    viewModel.detectedObjectName = "Coffee Cup"
                    viewModel.adjustableROI = CGRect(x: 100, y: 100, width: 200, height: 200)
                }
                .previewDisplayName("Active Detection")
            
            ARTranslationView(arViewModel: arViewModel, isActiveTab: true)
                .environmentObject(mockTranslationService)
                .onAppear {
                    let settingsVM = SettingsViewModel()
                    settingsVM.isExpanded = true
                }
                .previewDisplayName("Settings Expanded")
        }
    }
}

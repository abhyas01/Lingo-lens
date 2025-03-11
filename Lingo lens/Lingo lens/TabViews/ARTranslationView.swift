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
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var arViewModel: ARViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    @State private var previousSize: CGSize = .zero
    @State private var showInstructions = false
    @State private var alreadyResumedARSession = false
    @State private var showAlertAboutReset = false
    @State private var neverShowAlertAboutReset = false
    @State private var isViewActive = false

    @EnvironmentObject var translationService: TranslationService

    var body: some View {
        NavigationStack {
            Group {
                if cameraPermissionManager.showPermissionAlert {
                    CameraPermissionView(
                        openSettings: {
                            cameraPermissionManager.openAppSettings()
                        },
                        recheckPermission: {
                            cameraPermissionManager.checkPermission()
                        }
                    )
                } else {
                    mainARView
                        .withARErrorHandling()
                }
            }
            .navigationTitle("Translate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        arViewModel.isDetectionActive = false
                        arViewModel.detectedObjectName = ""
                        showInstructions = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .accessibilityLabel("Instructions")
                            .accessibilityHint("Learn how to use the Translate Feature")
                    }
                }
            }
        }
        .onAppear {
            isViewActive = true
            cameraPermissionManager.checkPermission()
            if !cameraPermissionManager.showPermissionAlert {
                DispatchQueue.main.async {
                    arViewModel.resetAnnotations()
                    arViewModel.resumeARSession()
                    alreadyResumedARSession = true
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                if isViewActive && !alreadyResumedARSession {
                    if !cameraPermissionManager.showPermissionAlert {
                        arViewModel.resetAnnotations()
                        arViewModel.resumeARSession()
                    }
                }
            case .background:
                arViewModel.pauseARSession()
                arViewModel.resetAnnotations()
                alreadyResumedARSession = false
                showAlertAboutReset = neverShowAlertAboutReset ? false : true
            default:
                break
            }
        }
        .onDisappear {
            isViewActive = false
            arViewModel.pauseARSession()
            arViewModel.resetAnnotations()
            showAlertAboutReset = neverShowAlertAboutReset ? false : true
        }
    }
    
    private var mainARView: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
            
            if arViewModel.isDetectionActive {
                boundingBoxView
            }
            
            VStack {
                if arViewModel.isDetectionActive {
                    DetectionLabel(detectedObjectName: arViewModel.detectedObjectName)
                        .padding(.top, 10)
                }
                
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
        .alert("Label Removal Warning", isPresented: $showAlertAboutReset) {
            Button("Ok") {}
            Button("Don't Warn Again", role: .cancel) {
                neverShowAlertAboutReset = true
            }
        } message: {
            Text("Whenever you leave the Translate tab, all labels will be removed from the objects in the real world.")
        }
        
        .animation(.easeInOut, value: arViewModel.showPlacementError)
        
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
            ARTranslationView(arViewModel: arViewModel)
                .environmentObject(mockTranslationService)
                .previewDisplayName("Normal State")
            
            ARTranslationView(arViewModel: arViewModel)
                .environmentObject(mockTranslationService)
                .onAppear {
                    let viewModel = ARViewModel()
                    viewModel.isDetectionActive = true
                    viewModel.detectedObjectName = "Coffee Cup"
                    viewModel.adjustableROI = CGRect(x: 100, y: 100, width: 200, height: 200)
                }
                .previewDisplayName("Active Detection")
            
            ARTranslationView(arViewModel: arViewModel)
                .environmentObject(mockTranslationService)
                .onAppear {
                    let settingsVM = SettingsViewModel()
                    settingsVM.isExpanded = true
                }
                .previewDisplayName("Settings Expanded")
        }
    }
}

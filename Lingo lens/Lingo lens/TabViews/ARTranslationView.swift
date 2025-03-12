//
//  ARTranslationView.swift
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
    
    @State private var currentOrientation = UIDevice.current.orientation

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
            
            setupOrientationObserver()
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
            
            // Clean up observer when view disappears
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }

    private func setupOrientationObserver() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [self] _ in
            let newOrientation = UIDevice.current.orientation
            if newOrientation.isValidInterfaceOrientation && newOrientation != currentOrientation {
                currentOrientation = newOrientation
                
                if let sceneView = arViewModel.sceneView {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let oldContainerSize = previousSize
                        let newContainerSize = sceneView.bounds.size

                        guard abs(oldContainerSize.width - newContainerSize.width) > 1 ||
                              abs(oldContainerSize.height - newContainerSize.height) > 1 else {
                            return
                        }

                        let margin: CGFloat = 16

                        let currentROI = arViewModel.adjustableROI
                        let relativeX = (currentROI.midX - margin) / (oldContainerSize.width - 2 * margin)
                        let relativeY = (currentROI.midY - margin) / (oldContainerSize.height - 2 * margin)

                        let maxWidth = newContainerSize.width - (2 * margin)
                        let maxHeight = newContainerSize.height - (2 * margin)
                        
                        let scaleRatio = min(maxWidth / maxHeight, 1.0)
                        let newWidth = min(currentROI.width * scaleRatio, maxWidth)
                        let newHeight = min(currentROI.height * scaleRatio, maxHeight)

                        let newMidX = margin + (relativeX * (newContainerSize.width - 2 * margin))
                        let newMidY = margin + (relativeY * (newContainerSize.height - 2 * margin))
                        
                        let newOriginX = newMidX - (newWidth / 2)
                        let newOriginY = newMidY - (newHeight / 2)

                        var newROI = CGRect(
                            x: newOriginX,
                            y: newOriginY,
                            width: newWidth,
                            height: newHeight
                        )

                        newROI = enforceMarginConstraints(newROI, in: newContainerSize)
                        
                        arViewModel.adjustableROI = newROI
                        previousSize = newContainerSize
                    }
                }
            }
        }
    }
    
    private func enforceMarginConstraints(_ rect: CGRect, in containerSize: CGSize) -> CGRect {
        let margin: CGFloat = 16
        let minBoxSize: CGFloat = 100
        
        var newRect = rect
        
        newRect.size.width = max(minBoxSize, min(newRect.size.width, containerSize.width - (2 * margin)))
        newRect.size.height = max(minBoxSize, min(newRect.size.height, containerSize.height - (2 * margin)))
        
        newRect.origin.x = max(margin, min(newRect.origin.x, containerSize.width - newRect.size.width - margin))
        newRect.origin.y = max(margin, min(newRect.origin.y, containerSize.height - newRect.size.height - margin))
        
        return newRect
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
                        let margin: CGFloat = 16

                        let maxBoxWidth = min(boxSize, geo.size.width - (2 * margin))
                        let maxBoxHeight = min(boxSize, geo.size.height - (2 * margin))
                        
                        arViewModel.adjustableROI = CGRect(
                            x: (geo.size.width - maxBoxWidth) / 2,
                            y: (geo.size.height - maxBoxHeight) / 2,
                            width: maxBoxWidth,
                            height: maxBoxHeight
                        )
                    }
                    previousSize = geo.size
                }
                
                .onChange(of: geo.size) { oldSize, newSize in
                    guard abs(oldSize.width - newSize.width) > 1 || abs(oldSize.height - newSize.height) > 1 else {
                        return
                    }

                    let adjustedROI = arViewModel.adjustableROI.resizedAndClamped(from: oldSize, to: newSize)
                    let constrainedROI = enforceMarginConstraints(adjustedROI, in: newSize)
                    
                    arViewModel.adjustableROI = constrainedROI
                    
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

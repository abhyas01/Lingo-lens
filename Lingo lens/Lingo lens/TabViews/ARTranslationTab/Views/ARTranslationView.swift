//
//  ARTranslationView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import AVFoundation

/// Main view for AR translation feature
/// Manages camera permission, AR session, detection box, and child views
struct ARTranslationView: View {
    
    // Tracks app state changes (foreground/background)
    @Environment(\.scenePhase) private var scenePhase
    
    // Main view model that handles AR state and logic
    @ObservedObject var arViewModel: ARViewModel
    
    // View model for expanding/collapsing settings panel
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    // Manages camera permission requests and state
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    
    // Tracks previous screen size for adjusting ROI on rotation
    @State private var previousSize: CGSize = .zero
    
    // Controls visibility of instructions sheet
    @State private var showInstructions = DataManager.shared.hasDismissedInstructions() ? false : true
    
    // Prevents redundant AR session resumes
    @State private var alreadyResumedARSession = false
    
    // Controls alert about label reset when tab changes
    @State private var showAlertAboutReset = false
    
    // Tracks if view is currently visible
    @State private var isViewActive = false
    
    // Remembers user preference to not show reset warning
    @State private var neverShowAlertAboutReset: Bool = DataManager.shared.getNeverShowLabelRemovalWarning()
    
    // For handling device orientation changes
    @State private var currentOrientation = UIDevice.current.orientation
    
    // Loading state for AR session
    @State private var isARSessionLoading = true
    
    // To show rating alert on 3rd launch
    // if instructions sheet needs to be presented
    // then we set it to false so that the instructions
    // sheet is not dismissed because of the alert
    @State private var showRatingAlert: Bool = !DataManager.shared.hasDismissedInstructions() ? false : DataManager.shared.shouldShowRatingPrompt()

    // Access to translation service
    @EnvironmentObject var translationService: TranslationService

    var body: some View {
        NavigationStack {
            Group {
                if cameraPermissionManager.showPermissionAlert {
                    
                    // Show permission view if camera access not granted
                    CameraPermissionView(
                        openSettings: {
                            cameraPermissionManager.openAppSettings()
                        }
                    )
                } else {
                    if isARSessionLoading {
                        
                        // Loading state while AR session initializes
                        ZStack {
                            Color.black.edgesIgnoringSafeArea(.all)
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        }
                        .transition(.opacity)
                    } else {
                        
                        // Main AR view when everything is ready
                        mainARView
                            .withARErrorHandling()
                    }
                }
            }
            .navigationTitle("Translate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !cameraPermissionManager.showPermissionAlert && !isARSessionLoading {
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        
                        // Info button to show instructions
                        Button(action: {
                            print("Translation's info button pressed")
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
                        .disabled(showInstructions)
                    }
                }
            }
        }
    
        .onAppear {
            isViewActive = true
            cameraPermissionManager.startChecking()
            
            // Setup AR session if permission is granted
            if !cameraPermissionManager.showPermissionAlert {
                DispatchQueue.main.async {
                    arViewModel.resetAnnotations()
                    arViewModel.resumeARSession()
                    alreadyResumedARSession = true
                    
                    // Hide loading screen after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isARSessionLoading = false
                        }
                    }
                }
            }
            
            setupOrientationObserver()
        }
        
        // Observe camera permission changes
        .onChange(of: cameraPermissionManager.showPermissionAlert) { oldValue, newValue in
            
            // When permission changes from denied to granted
            if oldValue == true && newValue == false {
                
                DispatchQueue.main.async {
                    arViewModel.resetAnnotations()
                    arViewModel.resumeARSession()
                    alreadyResumedARSession = true
                    
                    // Hide loading screen after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isARSessionLoading = false
                        }
                    }
                }
            }
        }
        
        // Handle app state changes (background/foreground)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                
                // Resume AR session when app becomes active
                if isViewActive {
                    cameraPermissionManager.startChecking()
                    
                    if !alreadyResumedARSession {
                        if !cameraPermissionManager.showPermissionAlert {
                            arViewModel.resetAnnotations()
                            arViewModel.resumeARSession()
                        }
                    }
                }
                
            case .background:
                
                cameraPermissionManager.stopChecking()

                // Pause AR session when app goes to background
                arViewModel.pauseARSession()
                arViewModel.resetAnnotations()
                alreadyResumedARSession = false
                
                // Show reset warning unless disabled
                if !neverShowAlertAboutReset {
                    showAlertAboutReset = true
                }
                
            default:
                break
            }
        }
        .onDisappear {
            cameraPermissionManager.stopChecking()

            // Clean up when view disappears
            isViewActive = false
            arViewModel.pauseARSession()
            arViewModel.resetAnnotations()
            
            // Show reset warning unless disabled
            if !neverShowAlertAboutReset {
                showAlertAboutReset = true
            }
            
            // Remove orientation observer
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
    
    /// Main AR view that contains camera feed, detection UI, and controls
    private var mainARView: some View {
        ZStack {
            
            // AR camera view container
            ARViewContainer(arViewModel: arViewModel)
            
            // Detection box overlay (only shown when detection is active)
            if arViewModel.isDetectionActive {
                boundingBoxView
            }
            
            VStack {
                
                // Top section - shows detection status
                if arViewModel.isDetectionActive {
                    DetectionLabel(detectedObjectName: arViewModel.detectedObjectName)
                        .padding(.top, 10)
                }
                
                // Error message when annotation placement fails
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
                
                // Bottom control bar
                ControlBar(
                    arViewModel: arViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
            
            // Overlay when deleting an annotation
            if arViewModel.isDeletingAnnotation {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            Text("Removing label...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Settings panel (slides up from bottom)
            if settingsViewModel.isExpanded {
                SettingsPanel(
                    arViewModel: arViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
        }
        
        // Instructions sheet
        .sheet(isPresented: $showInstructions) {
            InstructionsView(ratingAlert: $showRatingAlert)
        }
        
        // Alert for rating the app
        .alert("Enjoying Lingo Lens?", isPresented: $showRatingAlert) {
            
            // Rate now button - takes user to App Store
            Button("Rate Now") {
                
                DataManager.shared.markRatingPromptAsShown()
                
                // Open App Store - replace with your app ID
                if let url = URL(string: "https://apps.apple.com/") {
                    UIApplication.shared.open(url)
                }
            }
            
            // Later button - just dismisses for now
            Button("Later") {
                DataManager.shared.markRatingPromptAsShown()
            }
            
            // Don't ask again button
            Button("Don't Ask Again", role: .cancel) {
                DataManager.shared.setNeverAskForRating()
                DataManager.shared.markRatingPromptAsShown()
            }
        } message: {
            Text("If you enjoy using our app, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!")
        }
        
        // Alert about label removal when leaving tab
        .alert("Label Removal Warning", isPresented: $showAlertAboutReset) {
            Button("Ok") {}
            Button("Don't Warn Again", role: .cancel) {
                DataManager.shared.saveNeverShowLabelRemovalWarning(true)
                neverShowAlertAboutReset = true
            }
        } message: {
            Text("Whenever you leave the Translate tab, all labels will be removed from the objects in the real world.")
        }
        
        // Alert to confirm annotation deletion
        .alert("Remove Label", isPresented: $arViewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                arViewModel.annotationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                arViewModel.deleteAnnotation()
            }
        } message: {
            Text("Remove the \"\(arViewModel.annotationNameToDelete)\" label?")
        }
        
        // Smooth animation for error messages
        .animation(.easeInOut, value: arViewModel.showPlacementError)
        
        // Annotation detail sheet (shows translation)
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
    
    /// View that handles the draggable detection box
    private var boundingBoxView: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    
                    // Initial setup of detection box in center of screen
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
                
                // Handle container size changes (like rotation)
                .onChange(of: geo.size) { oldSize, newSize in
                    guard abs(oldSize.width - newSize.width) > 1 || abs(oldSize.height - newSize.height) > 1 else {
                        return
                    }

                    // Resize and reposition the detection box
                    let adjustedROI = arViewModel.adjustableROI.resizedAndClamped(from: oldSize, to: newSize)
                    let constrainedROI = enforceMarginConstraints(adjustedROI, in: newSize)
                    
                    arViewModel.adjustableROI = constrainedROI
                    
                    previousSize = newSize
                }
            
            // The actual draggable/resizable box
            AdjustableBoundingBox(
                roi: $arViewModel.adjustableROI,
                containerSize: geo.size
            )
        }
    }
    
    /// Sets up observer for device orientation changes
    /// Adjusts detection box when orientation changes
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

                        // Only adjust if size changed significantly
                        guard abs(oldContainerSize.width - newContainerSize.width) > 1 ||
                              abs(oldContainerSize.height - newContainerSize.height) > 1 else {
                            return
                        }

                        let margin: CGFloat = 16

                        // Calculate relative position to maintain proportional placement
                        let currentROI = arViewModel.adjustableROI
                        let relativeX = (currentROI.midX - margin) / (oldContainerSize.width - 2 * margin)
                        let relativeY = (currentROI.midY - margin) / (oldContainerSize.height - 2 * margin)

                        let maxWidth = newContainerSize.width - (2 * margin)
                        let maxHeight = newContainerSize.height - (2 * margin)
                        
                        // Calculate new size while maintaining aspect ratio
                        let scaleRatio = min(maxWidth / maxHeight, 1.0)
                        let newWidth = min(currentROI.width * scaleRatio, maxWidth)
                        let newHeight = min(currentROI.height * scaleRatio, maxHeight)

                        // Calculate new position based on relative coordinates
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

                        // Ensure box stays within screen margins
                        newROI = enforceMarginConstraints(newROI, in: newContainerSize)
                        
                        arViewModel.adjustableROI = newROI
                        previousSize = newContainerSize
                    }
                }
            }
        }
    }
    
    /// Ensures detection box stays within screen margins
    /// Enforces minimum size and maximum boundaries
    private func enforceMarginConstraints(_ rect: CGRect, in containerSize: CGSize) -> CGRect {
        let margin: CGFloat = 16
        let minBoxSize: CGFloat = 100
        
        var newRect = rect
        
        // Enforce minimum and maximum width
        newRect.size.width = max(minBoxSize, min(newRect.size.width, containerSize.width - (2 * margin)))
        newRect.size.height = max(minBoxSize, min(newRect.size.height, containerSize.height - (2 * margin)))
        
        // Enforce margin constraints for origin
        newRect.origin.x = max(margin, min(newRect.origin.x, containerSize.width - newRect.size.width - margin))
        newRect.origin.y = max(margin, min(newRect.origin.y, containerSize.height - newRect.size.height - margin))
        
        return newRect
    }
}

#Preview("Normal State") {
    let mockTranslationService = TranslationService()
    mockTranslationService.availableLanguages = [
        AvailableLanguage(locale: .init(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: .init(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: .init(languageCode: "de", region: "DE"))
    ]
    
    let arVM = ARViewModel()
    
    return ARTranslationView(arViewModel: arVM)
        .environmentObject(mockTranslationService)
        .environmentObject(AppearanceManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Active Detection") {
    let mockTranslationService = TranslationService()
    mockTranslationService.availableLanguages = [
        AvailableLanguage(locale: .init(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: .init(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: .init(languageCode: "de", region: "DE"))
    ]
    
    let arVM = ARViewModel()
    arVM.isDetectionActive = true
    arVM.detectedObjectName = "Coffee Cup"
    arVM.adjustableROI = CGRect(x: 100, y: 100, width: 200, height: 200)
    
    return ARTranslationView(arViewModel: arVM)
        .environmentObject(mockTranslationService)
        .environmentObject(AppearanceManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Settings Expanded") {
    let mockTranslationService = TranslationService()
    mockTranslationService.availableLanguages = [
        AvailableLanguage(locale: .init(languageCode: "es", region: "ES")),
        AvailableLanguage(locale: .init(languageCode: "fr", region: "FR")),
        AvailableLanguage(locale: .init(languageCode: "de", region: "DE"))
    ]
    
    let arVM = ARViewModel()
    let settingsVM = SettingsViewModel()
    settingsVM.isExpanded = true
    
    return ARTranslationView(arViewModel: arVM)
        .environmentObject(mockTranslationService)
        .environmentObject(AppearanceManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

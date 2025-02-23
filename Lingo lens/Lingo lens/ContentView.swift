//
//  ContentView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import AVFoundation

struct ContentView: View {
    @StateObject private var arViewModel = ARViewModel()
    @State private var previousSize: CGSize = .zero
    @State private var isSettingsExpanded = false
    @State private var showLanguageSelection = false
    @State private var showCameraPermissionAlert = false
    
    @EnvironmentObject var translationService: TranslationService

    var body: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Conditional bounding box display
            if arViewModel.isDetectionActive {
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
                        .onChange(of: geo.size) {
                            guard geo.size != previousSize else { return }
                            arViewModel.adjustableROI = arViewModel.adjustableROI
                                .resizedAndClamped(from: previousSize, to: geo.size)
                            previousSize = geo.size
                        }
                    
                    AdjustableBoundingBox(
                        roi: $arViewModel.adjustableROI,
                        containerSize: geo.size
                    )
                }
            }
            
            VStack {
                // Detection label
                if arViewModel.isDetectionActive {
                    let labelText = arViewModel.detectedObjectName.isEmpty ?
                    "Couldn't detect. Keep moving / Fit the object in the box / Move closer." :
                    arViewModel.detectedObjectName
                    
                    let labelBackground = arViewModel.detectedObjectName.isEmpty ?
                    Color.red.opacity(0.8) :
                    Color.green.opacity(0.8)
                    
                    Text(labelText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(8)
                        .background(labelBackground)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 50)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Bottom control bar
                HStack {
                    // Settings button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isSettingsExpanded.toggle()
                            if isSettingsExpanded {
                                arViewModel.isDetectionActive = false
                                arViewModel.detectedObjectName = ""
                            }
                        }
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading)
                    .rotation3DEffect(
                        .degrees(isSettingsExpanded ? 90 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    
                    Spacer()
                    
                    // Detection toggle button
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
                    
                    Spacer()
                    
                    // Add annotation button
                    Button(action: {
                        guard !arViewModel.detectedObjectName.isEmpty else { return }
                        arViewModel.addAnnotation()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(
                                arViewModel.detectedObjectName.isEmpty || !arViewModel.isDetectionActive ?
                                Color.gray : Color.blue
                            )
                            .padding()
                    }
                    .disabled(arViewModel.detectedObjectName.isEmpty || !arViewModel.isDetectionActive)
                }
            }
            
            // Settings panel
            if isSettingsExpanded {
                VStack {
                    HStack {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                isSettingsExpanded = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Language selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Language")
                                .foregroundColor(.white)
                            
                            Button(action: {
                                showLanguageSelection = true
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
                        
                        // Annotation size control
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Annotation Size")
                                .foregroundColor(.white)
                            
                            Slider(value: $arViewModel.annotationScale,
                                   in: 0.2...3.5,
                                   step: 0.1)
                        }
                        
                        // Clear annotations button
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
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(
                selectedLanguage: $arViewModel.selectedLanguage,
                isPresented: $showLanguageSelection
            )
            .environmentObject(translationService)
        }
        .sheet(isPresented: $arViewModel.isShowingAnnotationDetail) {
            if let originalText = arViewModel.selectedAnnotationText {
                AnnotationDetailView(originalText: originalText, targetLanguage: arViewModel.selectedLanguage)
                    .environmentObject(translationService)
            }
        }
        .onAppear(perform: checkCameraPermission)
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Cancel", role: .cancel) {
                // Check again after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkCameraPermission()
                }
            }
            Button("Open Settings") {
                openAppSettings()
                // Check again after returning from settings
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkCameraPermission()
                }
            }
        } message: {
            Text("Lingo Lens cannot function without camera access. Please enable camera access in Settings to use the app.")
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraPermissionAlert = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showCameraPermissionAlert = true
        }
        
        // Set up periodic permission check
        if !showCameraPermissionAlert {
            // Check every 2 seconds when alert is not showing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                checkCameraPermission()
            }
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

extension CGRect {
    func resizedAndClamped(from oldSize: CGSize, to newSize: CGSize, margin: CGFloat = 8) -> CGRect {
        guard oldSize != .zero, newSize != .zero else { return self }
        
        let widthScale = newSize.width / oldSize.width
        let heightScale = newSize.height / oldSize.height
        
        var newRect = CGRect(
            x: self.origin.x * widthScale,
            y: self.origin.y * heightScale,
            width: self.width * widthScale,
            height: self.height * heightScale
        )
        
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        newRect.size.width = min(newRect.size.width, newSize.width - 2 * margin)
        newRect.size.height = min(newRect.size.height, newSize.height - 2 * margin)
        
        let minWidth: CGFloat = 100
        let minHeight: CGFloat = 100
        newRect.size.width = max(newRect.size.width, minWidth)
        newRect.size.height = max(newRect.size.height, minHeight)
        
        if newRect.maxX > newSize.width - margin {
            newRect.origin.x = newSize.width - margin - newRect.size.width
        }
        if newRect.maxY > newSize.height - margin {
            newRect.origin.y = newSize.height - margin - newRect.size.height
        }
        
        return newRect
    }
}

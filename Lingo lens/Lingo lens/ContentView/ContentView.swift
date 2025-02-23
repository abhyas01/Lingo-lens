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
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    @State private var previousSize: CGSize = .zero
    @State private var showInstructions = false
    @EnvironmentObject var translationService: TranslationService
    
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
                    Button(action: {
                        arViewModel.isDetectionActive = false
                        arViewModel.detectedObjectName = ""
                        showInstructions = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
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
}

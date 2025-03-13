//
//  ARViewContainer.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit

/// Main AR view wrapper - handles all the ARKit setup and scene configuration
/// Bridges between SwiftUI and UIKit by wrapping ARSCNView
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARViewModel
    
    // MARK: - View Setup

    /// Creates and configures the AR scene view with all needed settings
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        arViewModel.sceneView = sceneView
        
        // Setup world tracking with plane detection for annotations
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // Enable mesh occlusion if device supports it
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Start fresh AR session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        sceneView.showsStatistics = false
        
        // Add tap handler for annotations
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.75
        sceneView.addGestureRecognizer(longPressGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    /// Links to our coordinator for AR session handling
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(arViewModel: arViewModel)
    }
}

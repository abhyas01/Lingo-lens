//
//  ARViewContainer.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit

/// Bridge between SwiftUI and ARKit's ARSCNView
/// Handles AR session setup and gesture recognition
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARViewModel
    var translationService: TranslationService

    // MARK: - View Setup

    /// Creates and configures the AR scene view
    /// Sets up tracking configuration, gesture recognizers, and delegates
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()

        // Start with a black background until AR session loads
        sceneView.backgroundColor = .black

        // Connect the view to our coordinator for delegation
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        
        // Store a reference to the scene view in our view model and annotation manager
        arViewModel.sceneView = sceneView
        arViewModel.annotationManager.sceneView = sceneView
        
        // Set up AR world tracking with plane detection
        // Needed to find surfaces for placing annotations
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // Enable mesh occlusion on devices with LiDAR
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Start the AR session with a fresh configuration
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Hide debug statistics display
        sceneView.showsStatistics = false
        
        // Add tap handler for interacting with annotations
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Add long press handler for deleting annotations
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.50
        sceneView.addGestureRecognizer(longPressGesture)
        
        return sceneView
    }
    
    /// Empty update method - view updates are handled by the ARViewModel
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    /// Creates a coordinator to handle ARKit delegates and gestures
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(arViewModel: arViewModel, translationService: translationService)
    }
}

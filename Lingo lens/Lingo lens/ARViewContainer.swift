//  ARViewContainer.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        arViewModel.sceneView = sceneView  // Pass reference to our view model
        
        // Configure the AR session for world tracking and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
        sceneView.showsStatistics = false
        sceneView.debugOptions = [.showFeaturePoints]  // Optional for debugging
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed for now.
    }
    
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(arViewModel: arViewModel)
    }
}

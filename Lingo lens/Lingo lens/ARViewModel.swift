//
//  ARViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit

class ARViewModel: ObservableObject {
    @Published var detectedObjectName: String = ""
    // This rectangle is in view coordinates (in points).
    @Published var adjustableROI: CGRect = .zero
    
    // Holds a weak reference to our ARSCNView so we can add annotation nodes.
    weak var sceneView: ARSCNView?
    
    func addAnnotation() {
        // Ensure we have a valid ARSCNView and a current frame.
        guard let sceneView = sceneView,
              let _ = sceneView.session.currentFrame else { return }
        
        // Use the center of the screen.
        let centerPoint = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        // Create a raycast query from the center point.
        if let raycastQuery = sceneView.raycastQuery(from: centerPoint, allowing: .estimatedPlane, alignment: .any) {
            // Perform the raycast.
            let results = sceneView.session.raycast(raycastQuery)
            if let closestResult = results.first {
                // Create an anchor at the hit-test location.
                let anchor = ARAnchor(transform: closestResult.worldTransform)
                sceneView.session.add(anchor: anchor)
                
                // Create an annotation node (in English only for now).
                let annotationText = detectedObjectName.isEmpty ? "Annotation" : detectedObjectName
                let annotationNode = createAnnotationNode(with: annotationText)
                
                let node = SCNNode()
                node.addChildNode(annotationNode)
                node.transform = SCNMatrix4(closestResult.worldTransform)
                sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }
    
    private func createAnnotationNode(with text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.5)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let node = SCNNode(geometry: textGeometry)
        // Scale and center the text geometry so it appears correctly in AR.
        node.scale = SCNVector3(0.005, 0.005, 0.005)
        let (minBound, maxBound) = textGeometry.boundingBox
        node.pivot = SCNMatrix4MakeTranslation((minBound.x + maxBound.x) / 2, minBound.y, 0)
        return node
    }
}

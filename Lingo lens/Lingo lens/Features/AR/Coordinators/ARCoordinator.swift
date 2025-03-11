//
//  ARCoordinator.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import ARKit
import SceneKit
import Vision
import UIKit

/// Handles AR session updates and tap interactions for the object detection and annotation system
class ARCoordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    var arViewModel: ARViewModel
    private let objectDetectionManager = ObjectDetectionManager()
    
    init(arViewModel: ARViewModel) {
        self.arViewModel = arViewModel
        super.init()
    }
    
    // MARK: - Frame Processing
    
    /// Gets called on every camera frame when detection is active
    /// Crops the camera feed to the bounding box area and runs object detection
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard arViewModel.isDetectionActive,
              let sceneView = arViewModel.sceneView else { return }
        
        let pixelBuffer = frame.capturedImage
        
        let deviceOrientation = UIDevice.current.orientation
        let exifOrientation = deviceOrientation.exifOrientation
        
        // Convert screen ROI to normalized coordinates for Vision
        let screenWidth = sceneView.bounds.width
        let screenHeight = sceneView.bounds.height
        let roi = arViewModel.adjustableROI
        
        var nx = roi.origin.x / screenWidth
        var ny = 1.0 - ((roi.origin.y + roi.height) / screenHeight)
        var nw = roi.width  / screenWidth
        var nh = roi.height / screenHeight
        
        // Clamp values to prevent out-of-bounds
        if nx < 0 { nx = 0 }
        if ny < 0 { ny = 0 }
        if nx + nw > 1 { nw = 1 - nx }
        if ny + nh > 1 { nh = 1 - ny }
        
        objectDetectionManager.detectObjectCropped(
            pixelBuffer: pixelBuffer,
            exifOrientation: exifOrientation,
            normalizedROI: CGRect(x: nx, y: ny, width: nw, height: nh)
        ) { result in
            DispatchQueue.main.async {
                self.arViewModel.detectedObjectName = result ?? ""
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR session error: \(error.localizedDescription)")
    
        ARErrorManager.shared.showError(
            message: "AR camera session encountered an issue. Please try again.",
            retryAction: { [weak self] in
                self?.arViewModel.resumeARSession()
            }
        )
    }
    
    // MARK: - Annotation Interaction

    /// Handles taps on AR annotations in 3D space
    /// Uses hit-testing to find the closest annotation to the tap location
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView = arViewModel.sceneView else { return }
        let location = gesture.location(in: sceneView)
        
        var closestAnnotation: (distance: CGFloat, text: String)? = nil

        // Search through all annotations to find the one that was tapped
        for annotation in arViewModel.annotationNodes {
            guard let planeNode = annotation.node.childNode(withName: "annotationPlane", recursively: false),
                  let plane = planeNode.geometry as? SCNPlane,
                  let material = plane.firstMaterial,
                  let skScene = material.diffuse.contents as? SKScene else { continue }

            let hitResults = sceneView.hitTest(location, options: [
                .boundingBoxOnly: false,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])
            
            guard let hitResult = hitResults.first(where: { $0.node == planeNode }) else { continue }
            
            // Convert hit location to annotation's local space
            let localPoint = hitResult.localCoordinates
            let normalizedX = (CGFloat(localPoint.x) / CGFloat(plane.width)) + 0.5
            let normalizedY = (CGFloat(localPoint.y) / CGFloat(plane.height)) + 0.5
            
            let capsuleSize = skScene.size
            let cornerRadius: CGFloat = 50
            let skPoint = CGPoint(x: normalizedX * capsuleSize.width,
                                y: (1 - normalizedY) * capsuleSize.height)
            
            // Check if tap is within annotation's capsule shape
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: capsuleSize),
                                  cornerRadius: cornerRadius)
            
            if path.contains(skPoint) {
                // Calculate distance to tap for closest annotation detection
                let worldPos = planeNode.worldPosition
                let projectedCenter = sceneView.projectPoint(worldPos)
                let center = CGPoint(x: CGFloat(projectedCenter.x), y: CGFloat(projectedCenter.y))
                let dx = center.x - location.x
                let dy = center.y - location.y
                let distance = hypot(dx, dy)
                
                if closestAnnotation == nil || distance < closestAnnotation!.distance {
                    closestAnnotation = (distance, annotation.originalText)
                }
            }
        }
        
        // Show translation sheet for tapped annotation
        if let closest = closestAnnotation {
            arViewModel.selectedAnnotationText = closest.text
            arViewModel.isShowingAnnotationDetail = true
            arViewModel.isDetectionActive = false
        }

    }

}

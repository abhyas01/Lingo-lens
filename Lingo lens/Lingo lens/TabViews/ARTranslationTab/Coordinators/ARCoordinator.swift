//
//  ARCoordinator.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import ARKit
import SceneKit
import Vision
import SwiftUI

/// Connects AR session events to the ARViewModel
/// Handles camera frames, detects objects, and manages user interactions with AR annotations
class ARCoordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    
    // Reference to view model that holds AR state
    var arViewModel: ARViewModel
    
    // Tracks the number of frames with normal tracking to ensure stability
    private var frameCounter = 0
    
    // Number of consecutive frames with normal tracking required before considering AR session stable
    private let requiredFramesForStability = 10
    
    // Tracks how long we've been in a limited tracking state
    private var timeInLimitedState: TimeInterval = 0
    
    // Maximum time to wait in limited tracking state before proceeding anyway (3 seconds)
    private let maxLimitedStateWaitTime: TimeInterval = 3.0
    
    // Timestamp of the last processed frame for calculating time deltas
    private var lastFrameTimestamp: TimeInterval = 0
    
    // Object detection logic is handled by separate manager
    private let objectDetectionManager = ObjectDetectionManager()
    
    init(arViewModel: ARViewModel) {
        self.arViewModel = arViewModel
        super.init()
    }
    
    // MARK: - Frame Processing
    
    /// Processes each camera frame when object detection is active
    /// Takes the camera image, crops it to the user-defined bounding box, then runs object detection
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Calculates time between frames to track duration in limited states
        let currentTime = frame.timestamp
        let deltaTime = lastFrameTimestamp > 0 ? currentTime - lastFrameTimestamp : 0
        lastFrameTimestamp = currentTime
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.arViewModel.isARSessionLoading {
                let currentTrackingState = frame.camera.trackingState
                
                switch currentTrackingState {
                    
                case .notAvailable:
                    
                    // Reset counters when tracking is completely unavailable
                    self.frameCounter = 0
                    self.timeInLimitedState = 0
                    
                case .limited(let reason):
                    
                    // Accumulate time spent in limited tracking state
                    self.timeInLimitedState += deltaTime
                    
                    // Show specific guidance based on the limitation type
                    switch reason {
                    case .initializing:
                        self.updateLoadingMessage("Initializing AR session...")
                    case .excessiveMotion, .insufficientFeatures, .relocalizing:
                        self.updateLoadingMessage("Loading...")
                    @unknown default:
                        self.updateLoadingMessage("Limited tracking")
                    }
                    
                    // If we've been in limited state too long, proceed anyway with a warning
                    if self.timeInLimitedState >= self.maxLimitedStateWaitTime {
                        print("⏱️ Proceeding with limited tracking after timeout")
                        withAnimation {
                            self.arViewModel.isARSessionLoading = false
                        }
                        self.timeInLimitedState = 0
                    }
                    
                case .normal:
                    
                    // Count consecutive frames with normal tracking
                    self.frameCounter += 1
                    
                    // Accumulate time spent
                    self.timeInLimitedState += deltaTime
                    
                    // Show encouraging message halfway through stabilization
                    if self.frameCounter == 5 {
                        self.updateLoadingMessage("Getting ready...")
                    }
                    
                    // When we've had enough stable frames, consider AR session ready
                    if self.frameCounter >= self.requiredFramesForStability {
                        withAnimation {
                            self.arViewModel.isARSessionLoading = false
                        }
                        self.frameCounter = 0
                        self.timeInLimitedState = 0
                    }
                }
            }
        }
        
        // Only process frames when detection is active and scene view exists
        guard arViewModel.isDetectionActive,
              let sceneView = arViewModel.sceneView else { return }
        
        // Only log occasionally to avoid flooding the console
        if frame.timestamp.truncatingRemainder(dividingBy: 1.0) < 0.01 {
            print("🎥 Processing AR frame at time: \(frame.timestamp)")
        }
        
        // Get the raw camera image
        let pixelBuffer = frame.capturedImage
        
        // Get current device orientation to properly orient image
        let deviceOrientation = UIDevice.current.orientation
        let exifOrientation = deviceOrientation.exifOrientation
        
        // Convert screen ROI (the yellow bounding box) to normalized coordinates (0-1 range)
        // Required by Vision framework for specifying the crop region
        let screenWidth = sceneView.bounds.width
        let screenHeight = sceneView.bounds.height
        let roi = arViewModel.adjustableROI
        
        // Convert screen coordinates to normalized coordinates
        // The Vision framework uses a different coordinate system (bottom-left origin)
        // That's why we need to adjust y-coordinate with 1.0 - value
        var nx = roi.origin.x / screenWidth
        var ny = 1.0 - ((roi.origin.y + roi.height) / screenHeight)
        var nw = roi.width  / screenWidth
        var nh = roi.height / screenHeight
        
        // Make sure coordinates stay within valid range (0-1)
        if nx < 0 { nx = 0 }
        if ny < 0 { ny = 0 }
        if nx + nw > 1 { nw = 1 - nx }
        if ny + nh > 1 { nh = 1 - ny }
        
        // Create a normalized ROI rect that will be captured
        let normalizedROI = CGRect(x: nx, y: ny, width: nw, height: nh)
         
        // Detach the processing from the ARFrame by using a separate method
        processFrameData(pixelBuffer: pixelBuffer,
                          exifOrientation: exifOrientation,
                          normalizedROI: normalizedROI)
    }
    
    /// Handles AR session errors by showing a user-friendly error message
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR session error: \(error.localizedDescription)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Small delay to avoid alert showing too quickly during normal transitions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ARErrorManager.shared.showError(
                    message: "AR camera session encountered an issue. Please try again.",
                    retryAction: { [weak self] in
                        guard let self = self else { return }
                        
                        // Try restarting the AR session if user taps retry
                        self.arViewModel.pauseARSession()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.arViewModel.resumeARSession()
                        }
                    }
                )
            }
        }
    }
    
    /// Helper method that doesn't retain the ARFrame
    private func processFrameData(pixelBuffer: CVPixelBuffer,
                                 exifOrientation: CGImagePropertyOrientation,
                                 normalizedROI: CGRect) {
        
        // Send the cropped region to object detection manager
        objectDetectionManager.detectObjectCropped(
            pixelBuffer: pixelBuffer,
            exifOrientation: exifOrientation,
            normalizedROI: normalizedROI
        ) { [weak self] result in
            
            // Update the UI with detection result on main thread using weak self
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.arViewModel.detectedObjectName = result ?? ""
            }
        }
    }
    
    /// Updates the loading message only if it's different from current message
    /// Prevents unnecessary UI updates when message hasn't changed
    private func updateLoadingMessage(_ message: String) {
        if self.arViewModel.loadingMessage != message {
            self.arViewModel.loadingMessage = message
        }
    }
    
    // MARK: - Annotation Interaction

    /// Handles taps on AR annotations
    /// Uses hit-testing to determine which annotation was tapped
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView = arViewModel.sceneView else { return }
        let location = gesture.location(in: sceneView)
        
        print("👆 Tap detected at screen position: \(location)")

        // Track the closest annotation to handle overlapping annotations
        var closestAnnotation: (distance: CGFloat, text: String)? = nil

        // Check if tap hit any annotation
        for annotation in arViewModel.annotationNodes {
            
            // Get the annotation's plane node (the visual part that can be tapped)
            guard let planeNode = annotation.node.childNode(withName: "annotationPlane", recursively: false),
                  let plane = planeNode.geometry as? SCNPlane,
                  let material = plane.firstMaterial,
                  let skScene = material.diffuse.contents as? SKScene else { continue }

            // Check if tap hit this particular node
            let hitResults = sceneView.hitTest(location, options: [
                .boundingBoxOnly: false,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])
            
            guard let hitResult = hitResults.first(where: { $0.node == planeNode }) else { continue }
            
            // Convert hit location to annotation's local coordinate space
            let localPoint = hitResult.localCoordinates
            let normalizedX = (CGFloat(localPoint.x) / CGFloat(plane.width)) + 0.5
            let normalizedY = (CGFloat(localPoint.y) / CGFloat(plane.height)) + 0.5
            
            // Check if tap is inside the capsule shape of the annotation
            let capsuleSize = skScene.size
            let cornerRadius: CGFloat = 50
            let skPoint = CGPoint(x: normalizedX * capsuleSize.width,
                                y: (1 - normalizedY) * capsuleSize.height)
            
            // Create a path representing the annotation's shape
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: capsuleSize),
                                  cornerRadius: cornerRadius)
            
            if path.contains(skPoint) {
                
                // Calculate distance to determine closest annotation if multiple are hit
                let worldPos = planeNode.worldPosition
                let projectedCenter = sceneView.projectPoint(worldPos)
                let center = CGPoint(x: CGFloat(projectedCenter.x), y: CGFloat(projectedCenter.y))
                let dx = center.x - location.x
                let dy = center.y - location.y
                let distance = hypot(dx, dy)
                
                // Keep track of closest annotation
                if closestAnnotation == nil || distance < closestAnnotation!.distance {
                    closestAnnotation = (distance, annotation.originalText)
                }
            }
        }
        
        // Show translation sheet for tapped annotation
        if let closest = closestAnnotation {
            print("✅ Tapped on annotation: \"\(closest.text)\"")
            arViewModel.selectedAnnotationText = closest.text
            arViewModel.isShowingAnnotationDetail = true
            arViewModel.isDetectionActive = false
        } else {
            print("ℹ️ No annotation found at tap location")
        }

    }
    
    /// Handles long press on annotations to show delete dialog
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let sceneView = arViewModel.sceneView, gesture.state == .began else { return }
        
        let location = gesture.location(in: sceneView)
        
        print("👇 Long press detected at screen position: \(location)")
        
        // Track the closest annotation to handle overlapping annotations
        var closestAnnotation: (distance: CGFloat, index: Int, text: String)? = nil
        
        // Check if long press hit any annotation
        for (index, annotation) in arViewModel.annotationNodes.enumerated() {
            guard let planeNode = annotation.node.childNode(withName: "annotationPlane", recursively: false),
                  let plane = planeNode.geometry as? SCNPlane,
                  let _ = plane.firstMaterial else { continue }
            
            // Check if long press hit this particular node
            let hitResults = sceneView.hitTest(location, options: [
                .boundingBoxOnly: false,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])
            
            guard let _ = hitResults.first(where: { $0.node == planeNode }) else { continue }
            
            // Calculate distance to determine closest annotation
            let worldPos = planeNode.worldPosition
            let projectedCenter = sceneView.projectPoint(worldPos)
            let center = CGPoint(x: CGFloat(projectedCenter.x), y: CGFloat(projectedCenter.y))
            let dx = center.x - location.x
            let dy = center.y - location.y
            let distance = hypot(dx, dy)
            
            // Keep track of closest annotation
            if closestAnnotation == nil || distance < closestAnnotation!.distance {
                closestAnnotation = (distance, index, annotation.originalText)
            }
        }
        
        // Show delete confirmation for the annotation
        if let closest = closestAnnotation {
            print("✅ Long-pressed on annotation: \"\(closest.text)\" at index \(closest.index)")

            arViewModel.isDetectionActive = false
            arViewModel.detectedObjectName = ""
            
            let textToShow = closest.text
            arViewModel.showDeleteAnnotationAlert(index: closest.index, objectName: textToShow)
        } else {
            print("ℹ️ No annotation found at long press location")
        }
    }

}

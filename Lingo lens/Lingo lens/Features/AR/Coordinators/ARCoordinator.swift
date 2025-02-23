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

class ARCoordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    var arViewModel: ARViewModel
    private let objectDetectionManager = ObjectDetectionManager()
    
    init(arViewModel: ARViewModel) {
        self.arViewModel = arViewModel
        super.init()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard arViewModel.isDetectionActive,
              let sceneView = arViewModel.sceneView else { return }
        
        let pixelBuffer = frame.capturedImage
        
        let deviceOrientation = UIDevice.current.orientation
        let exifOrientation = deviceOrientation.exifOrientation
        
        let screenWidth = sceneView.bounds.width
        let screenHeight = sceneView.bounds.height
        let roi = arViewModel.adjustableROI
        
        var nx = roi.origin.x / screenWidth
        var ny = 1.0 - ((roi.origin.y + roi.height) / screenHeight)
        var nw = roi.width  / screenWidth
        var nh = roi.height / screenHeight
        
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
    

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView = arViewModel.sceneView else { return }
        let location = gesture.location(in: sceneView)
        
        var closestAnnotation: (distance: CGFloat, text: String)? = nil

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
            
            let localPoint = hitResult.localCoordinates
            let normalizedX = (CGFloat(localPoint.x) / CGFloat(plane.width)) + 0.5
            let normalizedY = (CGFloat(localPoint.y) / CGFloat(plane.height)) + 0.5
            
            let capsuleSize = skScene.size
            let cornerRadius: CGFloat = 50
            let skPoint = CGPoint(x: normalizedX * capsuleSize.width,
                                y: (1 - normalizedY) * capsuleSize.height)
            
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: capsuleSize),
                                  cornerRadius: cornerRadius)
            
            if path.contains(skPoint) {
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
        
        if let closest = closestAnnotation {
            arViewModel.selectedAnnotationText = closest.text
            arViewModel.isShowingAnnotationDetail = true
            arViewModel.isDetectionActive = false
        }

    }

}

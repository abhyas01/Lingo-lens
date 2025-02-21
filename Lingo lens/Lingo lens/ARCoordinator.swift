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
        guard let sceneView = arViewModel.sceneView else { return }
        
        let pixelBuffer = frame.capturedImage
        
        // 1) Get device orientation -> exifOrientation
        let deviceOrientation = UIDevice.current.orientation
        let exifOrientation = deviceOrientation.exifOrientation
        
        // 2) Convert bounding box (top-left) to normalized (bottom-left)
        let screenWidth = sceneView.bounds.width
        let screenHeight = sceneView.bounds.height
        let roi = arViewModel.adjustableROI
        
        var nx = roi.origin.x / screenWidth
        
//        var ny = 1.0 - ((roi.origin.y + roi.height) / screenHeight)
        let yAdjustmentFactor: CGFloat = 0.15  // adjust this value as needed (10% of the ROI's height)
        var ny = 1.0 - ((roi.origin.y + roi.height) / screenHeight) - (roi.height / screenHeight) * yAdjustmentFactor

        var nw = roi.width  / screenWidth
        var nh = roi.height / screenHeight
        
        // clamp
        if nx < 0 { nx = 0 }
        if ny < 0 { ny = 0 }
        if nx + nw > 1 { nw = 1 - nx }
        if ny + nh > 1 { nh = 1 - ny }
        
        // 3) physically crop
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
}

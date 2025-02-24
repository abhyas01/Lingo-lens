//
//  ObjectDetectionManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import Foundation
import CoreML
import Vision
import CoreImage
import ImageIO

/// Handles real-time object detection using Vision framework and MobileNetV2 model
/// Processes cropped regions of camera frames to identify objects in view
class ObjectDetectionManager {
    private var visionModel: VNCoreMLModel?
    private let ciContext = CIContext()
    private let insideMargin: CGFloat = 4

    // MARK: - Setup

    /// Loads and configures ML model for object detection
    init() {
        do {
            let model = try MobileNetV2(configuration: MLModelConfiguration()).model
            visionModel = try VNCoreMLModel(for: model)
        } catch {
            visionModel = nil
        }
    }
    
    // MARK: - Image Processing & Detection

    /// Detects objects in a cropped region of a camera frame
    /// Only processes the part of the image inside the yellow box
    func detectObjectCropped(pixelBuffer: CVPixelBuffer,
                             exifOrientation: CGImagePropertyOrientation,
                             normalizedROI: CGRect,
                             completion: @escaping (String?) -> Void)
    {
        guard let visionModel = visionModel else {
            completion(nil)
            return
        }
        
        // Fix image orientation before cropping
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(forExifOrientation: exifOrientation.numericValue)
        
        // Convert normalized ROI to pixel coordinates
        let fullWidth = ciImage.extent.width
        let fullHeight = ciImage.extent.height
        
        let cropX = normalizedROI.origin.x * fullWidth
        let cropY = normalizedROI.origin.y * fullHeight
        let cropW = normalizedROI.width  * fullWidth
        let cropH = normalizedROI.height * fullHeight
        
        var cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        
        // Add a small margin inside the box for better results
        cropRect = cropRect.insetBy(dx: insideMargin, dy: insideMargin)
        
        // Skip tiny regions that would fail detection
        if cropRect.width < 10 || cropRect.height < 10 {
            completion(nil)
            return
        }
        
        // Make sure we're not trying to crop outside the image
        cropRect = ciImage.extent.intersection(cropRect)
        if cropRect.isEmpty {
            completion(nil)
            return
        }
        
        ciImage = ciImage.cropped(to: cropRect)
        
        // Convert to CGImage for Vision framework
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let _ = error {
                completion(nil)
                return
            }
            
            // Return highest confidence detection if it's above 30%
            guard let results = request.results as? [VNClassificationObservation],
                  let best = results.first,
                  best.confidence > 0.3 else {
                completion(nil)
                return
            }
            
            completion(best.identifier)
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
}

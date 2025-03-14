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

/// Handles object detection using Vision framework and FastViT model
/// Takes camera frames from AR session and identifies objects within user-defined regions
class ObjectDetectionManager {
    
    // ML model loaded from bundle for image classification
    private var visionModel: VNCoreMLModel?
    
    // CIContext for efficient image processing operations
    private let ciContext = CIContext()
    
    // Small margin to shrink the detection box slightly for better results
    private let insideMargin: CGFloat = 4

    // MARK: - Setup

    /// Sets up the ML model when manager is created
    /// Loads FastViTMA36F16 model for object recognition
    init() {
        do {
            // Load the model from the app bundle
            let model = try FastViTMA36F16(configuration: MLModelConfiguration()).model
            visionModel = try VNCoreMLModel(for: model)
        } catch {
            print("Failed to load object detection model: \(error.localizedDescription)")
            
            // Alert user about model loading failure
            ARErrorManager.shared.showError(
                message: "Could not load object detection model. The app may not work properly.",
                retryAction: nil
            )
            visionModel = nil
        }
    }
    
    // MARK: - Image Processing & Detection

    /// Detects objects in a specified region of a camera frame
    /// Only processes the part of the image that user has framed within the bounding box
    /// - Parameters:
    ///   - pixelBuffer: Raw camera frame from ARKit
    ///   - exifOrientation: Current orientation of device camera
    ///   - normalizedROI: Region of interest in normalized coordinates (0-1)
    ///   - completion: Callback with identified object name or nil if none found
    func detectObjectCropped(pixelBuffer: CVPixelBuffer,
                             exifOrientation: CGImagePropertyOrientation,
                             normalizedROI: CGRect,
                             completion: @escaping (String?) -> Void)
    {
        
        // Make sure we have the ML model loaded
        guard let visionModel = visionModel else {
            DispatchQueue.main.async {
                print("Object detection model is not available.")
                ARErrorManager.shared.showError(
                    message: "Object detection model is not available. Please restart the app.",
                    retryAction: nil
                )
            }
            completion(nil)
            return
        }
        
        // Convert pixel buffer to CIImage and fix orientation
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(forExifOrientation: exifOrientation.numericValue)
        
        // Convert normalized coordinates (0-1) to actual pixel coordinates
        let fullWidth = ciImage.extent.width
        let fullHeight = ciImage.extent.height
        
        let cropX = normalizedROI.origin.x * fullWidth
        let cropY = normalizedROI.origin.y * fullHeight
        let cropW = normalizedROI.width  * fullWidth
        let cropH = normalizedROI.height * fullHeight
        
        var cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        
        // Add a small margin inside the detection box for better results
        cropRect = cropRect.insetBy(dx: insideMargin, dy: insideMargin)
        
        // Skip processing for extremely small regions that would fail detection
        if cropRect.width < 10 || cropRect.height < 10 {
            completion(nil)
            return
        }
        
        // Make sure we're not trying to crop outside the image bounds
        cropRect = ciImage.extent.intersection(cropRect)
        if cropRect.isEmpty {
            completion(nil)
            return
        }
        
        // Crop the image to only the region inside the detection box
        ciImage = ciImage.cropped(to: cropRect)
        
        // Convert CIImage to CGImage for Vision framework
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            completion(nil)
            return
        }
        
        // Set up the ML request to detect objects in the image
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let _ = error {
                completion(nil)
                return
            }
            
            // Extract the top classification result
            // Only return it if confidence is above 50%
            guard let results = request.results as? [VNClassificationObservation],
                  let best = results.first,
                  best.confidence > 0.5 else {
                completion(nil)
                return
            }
            
            completion(best.identifier)
        }
        
        // Use center crop scaling to focus on the main object in the frame
        request.imageCropAndScaleOption = .centerCrop
        
        // Run the image through Vision framework
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision request failed: \(error.localizedDescription)")
            ARErrorManager.shared.showError(
                message: "Vision processing failed: \(error.localizedDescription)",
                retryAction: nil
            )
            completion(nil)
        }
    }
}

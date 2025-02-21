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

class ObjectDetectionManager {
    private var visionModel: VNCoreMLModel?
    private let ciContext = CIContext() // Reuse a single CIContext for performance
    
    // Adjust this if you want a bigger or smaller margin inside the user's bounding box.
    private let insideMargin: CGFloat = 4
    
    init() {
        let model = try! MobileNetV2FP16(configuration: MLModelConfiguration()).model
//        let model = try! FastViTT8F16(configuration: MLModelConfiguration()).model
        do {
            visionModel = try VNCoreMLModel(for: model)
        } catch {
            print("Error loading ML model: \(error)")
        }
    }
    
    // The physically-cropping version with a small inside margin.
    func detectObjectCropped(pixelBuffer: CVPixelBuffer,
                             exifOrientation: CGImagePropertyOrientation,
                             normalizedROI: CGRect,
                             completion: @escaping (String?) -> Void)
    {
        guard let visionModel = visionModel else {
            completion(nil)
            return
        }
        
        // 1) Create a CIImage from the CVPixelBuffer, oriented for how the user sees it.
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(forExifOrientation: exifOrientation.numericValue)
        
        let fullWidth = ciImage.extent.width
        let fullHeight = ciImage.extent.height
        
        // 2) Convert normalized ROI to absolute coords in CI space.
        // bottom-left origin for CIImage.
        let cropX = normalizedROI.origin.x * fullWidth
        let cropY = normalizedROI.origin.y * fullHeight
        let cropW = normalizedROI.width  * fullWidth
        let cropH = normalizedROI.height * fullHeight
        
        var cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        
        // 3) Inset the crop rect so we exclude a small boundary region.
        // This helps avoid picking up content just beyond the bounding box edge.
        cropRect = cropRect.insetBy(dx: insideMargin, dy: insideMargin)
        if cropRect.width < 10 || cropRect.height < 10 {
            // If it becomes too small or negative, skip detection entirely.
            completion(nil)
            return
        }
        
        // 4) Safely intersect with the CIImage’s extent (in case it goes out of bounds).
        cropRect = ciImage.extent.intersection(cropRect)
        if cropRect.isEmpty {
            completion(nil)
            return
        }
        
        // 5) Crop the CIImage
        ciImage = ciImage.cropped(to: cropRect)
        
        // 6) Convert the cropped CIImage to a CGImage
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from CIImage.")
            completion(nil)
            return
        }
        
        // 7) Create a VNCoreMLRequest
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error = error {
                print("Vision request error: \(error)")
                completion(nil)
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation],
                  let best = results.first,
                  best.confidence > 0.5 else {
                completion(nil)
                return
            }
            
            completion(best.identifier)
        }
        
        // .centerCrop or .scaleFit is fine; we’ve already physically cropped.
        request.imageCropAndScaleOption = .centerCrop
        
        // 8) Perform the request on the CGImage
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error)")
            completion(nil)
        }
    }
}

// Utility to map CGImagePropertyOrientation to Exif numeric
extension CGImagePropertyOrientation {
    var numericValue: Int32 {
        switch self {
        case .up:            return 1
        case .upMirrored:    return 2
        case .down:          return 3
        case .downMirrored:  return 4
        case .leftMirrored:  return 5
        case .right:         return 6
        case .rightMirrored: return 7
        case .left:          return 8
        @unknown default:    return 1
        }
    }
}

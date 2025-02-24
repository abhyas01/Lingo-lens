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
    private let ciContext = CIContext()
    private let insideMargin: CGFloat = 4

    init() {
        do {
            let model = try MobileNetV2FP16(configuration: MLModelConfiguration()).model
//            let model = try! FastViTT8F16(configuration: MLModelConfiguration()).model
            visionModel = try VNCoreMLModel(for: model)
        } catch {
            visionModel = nil
        }
    }
    
    
    func detectObjectCropped(pixelBuffer: CVPixelBuffer,
                             exifOrientation: CGImagePropertyOrientation,
                             normalizedROI: CGRect,
                             completion: @escaping (String?) -> Void)
    {
        guard let visionModel = visionModel else {
            completion(nil)
            return
        }
        
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(forExifOrientation: exifOrientation.numericValue)
        
        let fullWidth = ciImage.extent.width
        let fullHeight = ciImage.extent.height
        
        let cropX = normalizedROI.origin.x * fullWidth
        let cropY = normalizedROI.origin.y * fullHeight
        let cropW = normalizedROI.width  * fullWidth
        let cropH = normalizedROI.height * fullHeight
        
        var cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        
        cropRect = cropRect.insetBy(dx: insideMargin, dy: insideMargin)
        
        if cropRect.width < 10 || cropRect.height < 10 {
            completion(nil)
            return
        }
        
        cropRect = ciImage.extent.intersection(cropRect)
        if cropRect.isEmpty {
            completion(nil)
            return
        }
        
        ciImage = ciImage.cropped(to: cropRect)
        
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let _ = error {
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
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
}

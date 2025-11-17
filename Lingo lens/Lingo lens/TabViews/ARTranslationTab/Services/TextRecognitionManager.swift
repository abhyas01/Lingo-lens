//
//  TextRecognitionManager.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation
import Vision
import UIKit
import CoreImage

/// Manages text recognition (OCR) using Vision framework
class TextRecognitionManager: ObservableObject {

    // MARK: - Published Properties

    @Published var recognizedTexts: [RecognizedTextItem] = []
    @Published var isProcessing: Bool = false

    // MARK: - Private Properties

    private var recognizeTextRequest: VNRecognizeTextRequest?
    private var lastProcessTime: Date = Date()
    private let throttleInterval: TimeInterval = 0.5  // Max 2 FPS

    // MARK: - Initialization

    init() {
        setupTextRecognition()
    }

    // MARK: - Public Methods

    /// Recognizes text in a pixel buffer (from camera)
    /// - Parameters:
    ///   - pixelBuffer: The camera frame pixel buffer
    ///   - roi: Region of interest in normalized coordinates
    ///   - completion: Callback with recognized text items
    func recognizeText(
        in pixelBuffer: CVPixelBuffer,
        roi: CGRect,
        completion: @escaping ([RecognizedTextItem]) -> Void
    ) {
        // Throttle requests
        guard shouldProcessFrame() else { return }

        guard let request = recognizeTextRequest else {
            completion([])
            return
        }

        isProcessing = true

        // Set region of interest
        request.regionOfInterest = roi

        // Create request handler
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])

                if let results = request.results as? [VNRecognizedTextObservation] {
                    let items = self?.processTextObservations(results) ?? []

                    DispatchQueue.main.async {
                        self?.recognizedTexts = items
                        self?.isProcessing = false
                        completion(items)
                    }
                }
            } catch {
                Logger.debug("Text recognition error: \(error)")
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    completion([])
                }
            }
        }
    }

    /// Recognizes text in a UIImage
    /// - Parameters:
    ///   - image: The image to process
    ///   - completion: Callback with recognized text items
    func recognizeText(
        in image: UIImage,
        completion: @escaping ([RecognizedTextItem]) -> Void
    ) {
        guard let request = recognizeTextRequest,
              let cgImage = image.cgImage else {
            completion([])
            return
        }

        isProcessing = true

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: .up,
            options: [:]
        )

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])

                if let results = request.results as? [VNRecognizedTextObservation] {
                    let items = self?.processTextObservations(results) ?? []

                    DispatchQueue.main.async {
                        self?.recognizedTexts = items
                        self?.isProcessing = false
                        completion(items)
                    }
                }
            } catch {
                Logger.debug("Text recognition error: \(error)")
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    completion([])
                }
            }
        }
    }

    // MARK: - Private Methods

    private func setupTextRecognition() {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            // Results are handled in the completion callbacks
        }

        // Configuration
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.03  // 3% of image height

        // Support multiple languages if available
        if #available(iOS 16.0, *) {
            request.automaticallyDetectsLanguage = true
        }

        self.recognizeTextRequest = request
    }

    private func processTextObservations(_ observations: [VNRecognizedTextObservation]) -> [RecognizedTextItem] {
        var items: [RecognizedTextItem] = []

        for observation in observations {
            // Get top candidate
            guard let topCandidate = observation.topCandidates(1).first,
                  topCandidate.confidence > 0.5 else {
                continue
            }

            let item = RecognizedTextItem(
                text: topCandidate.string,
                confidence: topCandidate.confidence,
                boundingBox: observation.boundingBox,
                worldPosition: nil
            )

            items.append(item)
        }

        // Sort by vertical position (top to bottom)
        items.sort { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

        return items
    }

    private func shouldProcessFrame() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastProcessTime) >= throttleInterval else {
            return false
        }
        lastProcessTime = now
        return true
    }

    /// Combines adjacent text items into phrases
    func combineAdjacentTexts(_ items: [RecognizedTextItem]) -> [RecognizedTextItem] {
        guard !items.isEmpty else { return [] }

        var combined: [RecognizedTextItem] = []
        var currentGroup: [RecognizedTextItem] = [items[0]]

        for i in 1..<items.count {
            let current = items[i]
            let previous = items[i - 1]

            // Check if items are on the same line (similar Y coordinate)
            let verticalDistance = abs(current.boundingBox.origin.y - previous.boundingBox.origin.y)
            let horizontalDistance = current.boundingBox.origin.x - (previous.boundingBox.origin.x + previous.boundingBox.width)

            if verticalDistance < 0.02 && horizontalDistance < 0.05 {
                // Same line, add to group
                currentGroup.append(current)
            } else {
                // New line, combine current group
                if let combinedItem = combineGroup(currentGroup) {
                    combined.append(combinedItem)
                }
                currentGroup = [current]
            }
        }

        // Don't forget the last group
        if let combinedItem = combineGroup(currentGroup) {
            combined.append(combinedItem)
        }

        return combined
    }

    private func combineGroup(_ group: [RecognizedTextItem]) -> RecognizedTextItem? {
        guard !group.isEmpty else { return nil }

        if group.count == 1 {
            return group[0]
        }

        // Combine texts
        let combinedText = group.map { $0.text }.joined(separator: " ")

        // Average confidence
        let avgConfidence = group.reduce(0) { $0 + $1.confidence } / Float(group.count)

        // Union of bounding boxes
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        for item in group {
            minX = min(minX, item.boundingBox.origin.x)
            minY = min(minY, item.boundingBox.origin.y)
            maxX = max(maxX, item.boundingBox.origin.x + item.boundingBox.width)
            maxY = max(maxY, item.boundingBox.origin.y + item.boundingBox.height)
        }

        let combinedBoundingBox = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )

        return RecognizedTextItem(
            text: combinedText,
            confidence: avgConfidence,
            boundingBox: combinedBoundingBox,
            worldPosition: group.first?.worldPosition
        )
    }
}

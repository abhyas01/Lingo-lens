//
//  AnnotationManager.swift
//  Lingo lens
//
//  Created by Claude Code Review on 11/17/25.
//  Extracted from ARViewModel for better separation of concerns
//

import Foundation
import ARKit
import SceneKit
import SwiftUI

/// Manages 3D annotation placement and lifecycle in AR scenes
/// Handles annotation creation, deletion, scaling, and visual rendering
class AnnotationManager: ObservableObject {

    // MARK: - Published Properties

    /// Controls error alert when annotation can't be placed
    @Published var showPlacementError = false

    /// Error message when annotation placement fails
    @Published var placementErrorMessage = "Couldn't place label. Try:\n• Move closer to the surface\n• Point at a flat area\n• Ensure good lighting"

    /// Controls delete confirmation alert
    @Published var showDeleteConfirmation = false

    /// Tracks which annotation is being deleted
    @Published var annotationToDelete: Int? = nil

    /// Name of the annotation being deleted (shown in alert)
    @Published var annotationNameToDelete: String = ""

    /// Tracks whether deletion is in progress
    @Published var isDeletingAnnotation = false

    /// Tracks if we're currently placing an annotation
    @Published var isAddingAnnotation = false

    // MARK: - Properties

    /// All annotations placed in 3D space
    /// Contains the node, original text, and world position
    var annotationNodes: [(node: SCNNode, originalText: String, worldPos: SIMD3<Float>)] = []

    /// Current annotation scale factor
    var annotationScale: CGFloat = DataManager.shared.getAnnotationScale()

    /// Reference to AR scene view (set by parent)
    weak var sceneView: ARSCNView?

    // MARK: - Lifecycle

    deinit {
        Logger.debug("AnnotationManager deallocated")
    }

    // MARK: - Public Methods

    /// Shows delete confirmation alert for an annotation
    func showDeleteAnnotationAlert(index: Int, objectName: String) {
        annotationToDelete = index

        // Truncate long names with ellipsis
        if objectName.count > 15 {
            let endIndex = objectName.index(objectName.startIndex, offsetBy: 12)
            annotationNameToDelete = String(objectName[..<endIndex]) + "..."
        } else {
            annotationNameToDelete = objectName
        }
        showDeleteConfirmation = true
    }

    /// Removes an annotation from the AR scene
    func deleteAnnotation() {
        guard let index = annotationToDelete, index < annotationNodes.count else {
            Logger.warning("Invalid annotation index for deletion: \(String(describing: annotationToDelete))")
            return
        }

        Logger.debug("Deleting annotation at index \(index)")
        isDeletingAnnotation = true

        // Small delay to show deletion is happening
        DispatchQueue.main.asyncAfter(deadline: .now() + ARConstants.annotationDeleteDelay) { [weak self] in
            guard let self = self else { return }

            // Get the annotation and remove from scene
            let (node, _, _) = self.annotationNodes[index]
            Logger.debug("Removing annotation from scene")
            node.removeFromParentNode()

            // Remove from our tracking array
            self.annotationNodes.remove(at: index)
            Logger.info("Annotation deleted successfully - \(self.annotationNodes.count) annotations remaining")

            // Haptic feedback for deletion
            HapticManager.shared.annotationRemoved()

            // Reset state
            self.isDeletingAnnotation = false
            self.annotationToDelete = nil
            self.showDeleteConfirmation = false
        }
    }

    /// Updates the size of all annotations when scale changes
    func updateAllAnnotationScales(_ scale: CGFloat) {
        annotationScale = scale
        for (node, _, _) in annotationNodes {
            node.scale = SCNVector3(scale, scale, scale)
        }
    }

    /// Adds a new annotation at the center of the detection box
    func addAnnotation(objectName: String, at roi: CGRect) {
        // Prevent multiple simultaneous adds
        guard !isAddingAnnotation else {
            Logger.warning("Already adding an annotation - ignoring request")
            return
        }

        // Only add if we have a valid object name
        guard !objectName.isEmpty, !objectName.trimmingCharacters(in: .whitespaces).isEmpty else {
            Logger.warning("Cannot add annotation - no object detected")
            return
        }

        // Make sure AR is ready
        guard let sceneView = sceneView, sceneView.session.currentFrame != nil else {
            Logger.warning("AR scene view not ready")
            return
        }

        Logger.debug("Adding annotation for object: \"\(objectName)\"")
        isAddingAnnotation = true

        // Use center of the yellow box as placement point
        let roiCenter = CGPoint(x: roi.midX, y: roi.midY)
        Logger.debug("Attempting to place annotation at screen position: \(roiCenter)")

        // Try to find a plane at that point using raycasting
        if let query = sceneView.raycastQuery(from: roiCenter, allowing: .estimatedPlane, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let result = results.first {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // Double-check object name is still valid
                    guard !objectName.isEmpty else {
                        self.isAddingAnnotation = false
                        return
                    }

                    // Create annotation and add to scene
                    let annotationNode = self.createCapsuleAnnotation(with: objectName)
                    annotationNode.simdTransform = result.worldTransform
                    annotationNode.scale = SCNVector3(self.annotationScale, self.annotationScale, self.annotationScale)

                    // Store world position for later reference
                    let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x,
                                               result.worldTransform.columns.3.y,
                                               result.worldTransform.columns.3.z)
                    self.annotationNodes.append((annotationNode, objectName, worldPos))
                    sceneView.scene.rootNode.addChildNode(annotationNode)

                    // Haptic feedback for successful placement
                    HapticManager.shared.annotationPlaced()

                    // Reset state after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + ARConstants.annotationAddDelay) { [weak self] in
                        self?.isAddingAnnotation = false
                    }
                }
            } else {
                // No plane found - show placement error
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isAddingAnnotation = false

                    // Haptic feedback for error
                    HapticManager.shared.error()

                    if !self.showPlacementError {
                        self.showPlacementError = true

                        // Hide error after duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + ARConstants.placementErrorDuration) { [weak self] in
                            self?.showPlacementError = false
                        }
                    }
                }
            }
        } else {
            // Couldn't create raycast query
            DispatchQueue.main.async { [weak self] in
                self?.isAddingAnnotation = false
            }
        }
    }

    /// Removes all annotations from the scene
    func resetAnnotations() {
        Logger.debug("Clearing all annotations - count before reset: \(annotationNodes.count)")
        for (node, _, _) in annotationNodes {
            node.removeFromParentNode()
        }
        annotationNodes.removeAll()
        Logger.info("All annotations cleared")
    }

    // MARK: - Private Methods

    /// Creates a capsule-shaped annotation with text
    private func createCapsuleAnnotation(with text: String) -> SCNNode {
        let validatedText = text.isEmpty ? "Unknown Object" : text

        // Size calculations based on text length
        let textCount = CGFloat(validatedText.count)
        let planeWidth = min(
            max(ARConstants.annotationBaseWidth + textCount * ARConstants.annotationExtraWidthPerChar,
                ARConstants.annotationMinWidth),
            ARConstants.annotationMaxWidth
        )

        // Create a plane with rounded corners
        let plane = SCNPlane(width: planeWidth, height: ARConstants.annotationHeight)
        plane.cornerRadius = ARConstants.annotationCornerRadius

        // Use SpriteKit scene for the plane's contents
        plane.firstMaterial?.diffuse.contents = makeCapsuleSKScene(with: validatedText, width: planeWidth, height: ARConstants.annotationHeight)
        plane.firstMaterial?.isDoubleSided = true

        // Create node hierarchy
        let planeNode = SCNNode(geometry: plane)
        planeNode.name = "annotationPlane"
        planeNode.categoryBitMask = 1

        let containerNode = SCNNode()
        containerNode.name = "annotationContainer"
        containerNode.categoryBitMask = 1

        // Position the plane slightly above the anchor point
        containerNode.addChildNode(planeNode)
        planeNode.position = SCNVector3(0, ARConstants.annotationVerticalOffset, 0)
        containerNode.eulerAngles.x = -Float.pi / 2

        // Apply user's preferred scale
        containerNode.scale = SCNVector3(annotationScale, annotationScale, annotationScale)

        // Make annotation always face the camera
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y, .Z]
        containerNode.constraints = [billboard]

        return containerNode
    }

    /// Creates a 2D SpriteKit scene for the annotation's visual appearance
    private func makeCapsuleSKScene(with text: String, width: CGFloat, height: CGFloat) -> SKScene {
        let sceneSize = CGSize(width: SpriteKitConstants.annotationSceneWidth,
                               height: SpriteKitConstants.annotationSceneHeight)
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear

        // Create white capsule background
        let bgRect = CGRect(origin: .zero, size: sceneSize)
        let background = SKShapeNode(rect: bgRect, cornerRadius: SpriteKitConstants.capsuleCornerRadius)
        background.fillColor = .white
        background.strokeColor = .clear
        scene.addChild(background)

        // Container for text elements with flipped Y-axis
        let containerNode = SKNode()
        containerNode.setScale(1.0)
        containerNode.yScale = -1
        scene.addChild(containerNode)

        // Add chevron icon to indicate tappable
        let chevron = SKLabelNode(fontNamed: "SF Pro")
        chevron.text = "›"
        chevron.fontSize = SpriteKitConstants.chevronFontSize
        chevron.fontColor = .gray
        chevron.verticalAlignmentMode = .center
        chevron.horizontalAlignmentMode = .center
        chevron.position = CGPoint(x: sceneSize.width - SpriteKitConstants.chevronXOffset,
                                   y: -sceneSize.height / 2)
        containerNode.addChild(chevron)

        // Process text into lines that fit the capsule
        let processedLines = processTextIntoLines(text, maxCharsPerLine: TextProcessingConstants.maxCharsPerLine)
        let totalTextHeight = CGFloat(processedLines.count) * SpriteKitConstants.lineHeight
        let startY = (sceneSize.height + totalTextHeight) / 2 - SpriteKitConstants.lineHeight / 2

        // Add each line of text
        for (i, line) in processedLines.enumerated() {
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.text = line
            label.fontSize = SpriteKitConstants.labelFontSize
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center

            let yPosition = startY - (CGFloat(i) * SpriteKitConstants.lineHeight)
            label.position = CGPoint(
                x: (sceneSize.width - SpriteKitConstants.chevronXOffset) / 2,
                y: -yPosition
            )
            containerNode.addChild(label)
        }

        return scene
    }

    /// Handles text wrapping for annotation labels (optimized)
    private func processTextIntoLines(_ text: String, maxCharsPerLine: Int) -> [String] {
        var lines = [String]()
        var words = text.split(separator: " ")
        var currentLine = [String]()
        var currentLength = 0

        let ellipsis = TextProcessingConstants.ellipsis

        // Process words into lines with max 2 lines total
        for word in words {
            let wordLength = word.count
            let nextLength = currentLength + wordLength + (currentLine.isEmpty ? 0 : 1)

            if nextLength <= maxCharsPerLine {
                currentLine.append(String(word))
                currentLength = nextLength
            } else {
                if lines.count >= TextProcessingConstants.maxLines - 1 {
                    // On last allowed line - add ellipsis and stop
                    if !currentLine.isEmpty {
                        var lastLine = currentLine.joined(separator: " ")
                        if lastLine.count > maxCharsPerLine - ellipsis.count {
                            lastLine = String(lastLine.prefix(maxCharsPerLine - ellipsis.count)) + ellipsis
                        } else {
                            lastLine += ellipsis
                        }
                        lines.append(lastLine)
                    }
                    currentLine = []
                    break
                } else {
                    // Start new line
                    if !currentLine.isEmpty {
                        lines.append(currentLine.joined(separator: " "))
                        currentLine = [String(word)]
                        currentLength = wordLength
                    } else {
                        // Word is too long - truncate it
                        currentLine.append(String(word.prefix(maxCharsPerLine)))
                        currentLength = maxCharsPerLine
                    }
                }
            }

            if lines.count >= TextProcessingConstants.maxLines {
                break
            }
        }

        // Add final line if not empty and under limit
        if !currentLine.isEmpty && lines.count < TextProcessingConstants.maxLines {
            lines.append(currentLine.joined(separator: " "))
        }

        // Reverse order because SpriteKit's coordinate system is different
        return lines.reversed()
    }
}

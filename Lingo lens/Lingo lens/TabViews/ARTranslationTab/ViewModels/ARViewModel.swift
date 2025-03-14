//
//  ARViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit

/// Central view model that manages all AR translation features
/// Controls object detection state, annotations, and camera session
class ARViewModel: ObservableObject {
    
    // Tracks whether the AR session is active or paused
    enum ARSessionState {
        case active
        case paused
    }
    
    // MARK: - Published States
    
    // Current state of the AR session (active/paused)
    @Published var sessionState: ARSessionState = .active
    
    // Controls whether object detection is currently running
    @Published var isDetectionActive = false
    
    // Name of object currently detected within the ROI
    @Published var detectedObjectName: String = ""
    
    // The yellow box that defines where to look for objects
    @Published var adjustableROI: CGRect = .zero
    
    // Text for currently selected annotation (when tapped)
    @Published var selectedAnnotationText: String?
    
    // Whether to show the annotation detail sheet
    @Published var isShowingAnnotationDetail: Bool = false
    
    // Controls error alert when annotation can't be placed
    @Published var showPlacementError = false
    
    // Tracks if we're currently placing an annotation
    @Published var isAddingAnnotation = false
    
    // Error message when annotation placement fails
    @Published var placementErrorMessage = "Could not detect a plane to anchor annotation. Try again changing angle or moving around."
    
    // Controls delete confirmation alert
    @Published var showDeleteConfirmation = false
    
    // Tracks which annotation is being deleted
    @Published var annotationToDelete: Int? = nil
    
    // Name of the annotation being deleted (shown in alert)
    @Published var annotationNameToDelete: String = ""
    
    // Tracks whether deletion is in progress
    @Published var isDeletingAnnotation = false
    
    // Currently selected language for translations
    // Persists to UserDefaults when changed
    @Published var selectedLanguage: AvailableLanguage {
        didSet {
            DataManager.shared.saveSelectedLanguageCode(selectedLanguage.shortName())
        }
    }
    
    // Scale factor for annotation size
    // Persists to UserDefaults when changed
    @Published var annotationScale: CGFloat = DataManager.shared.getAnnotationScale() {
        didSet {
            DataManager.shared.saveAnnotationScale(annotationScale)
            updateAllAnnotationScales()
        }
    }

    // MARK: - Properties
    
    // Reference to AR scene view (set by ARViewContainer)
    weak var sceneView: ARSCNView?
    
    // All annotations placed in 3D space
    // Contains the node, original text, and world position
    var annotationNodes: [(node: SCNNode, originalText: String, worldPos: SIMD3<Float>)] = []
    
    
    // MARK: - Initialization
    
    // Default to Spanish as initial language
    init() {
        self.selectedLanguage = AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES"))
    }
    
    // MARK: - Class Methods
    
    /// Loads the previously selected language from UserDefaults
    /// Called when app starts or when available languages change
    func updateSelectedLanguageFromUserDefaults(availableLanguages: [AvailableLanguage]) {
        let savedLanguageCode = DataManager.shared.getSelectedLanguageCode()
    
        if let savedCode = savedLanguageCode,
           let savedLanguage = availableLanguages.first(where: { $0.shortName() == savedCode }) {
            
            // Use previously saved language if available
            self.selectedLanguage = savedLanguage
        } else if !availableLanguages.isEmpty {
            
            // Default to first available language if saved one isn't available
            self.selectedLanguage = availableLanguages.first!
            DataManager.shared.saveSelectedLanguageCode(selectedLanguage.shortName())
        }
    }

    /// Shows delete confirmation alert for an annotation
    /// Formats object name for display in the alert
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
    /// Called when user confirms deletion
    func deleteAnnotation() {
        guard let index = annotationToDelete, index < annotationNodes.count else { return }
        
        isDeletingAnnotation = true
        
        // Small delay to show deletion is happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Get the annotation and remove from scene
            let (node, _, _) = self.annotationNodes[index]
            node.removeFromParentNode()
            
            // Remove from our tracking array
            self.annotationNodes.remove(at: index)
            
            // Reset state
            self.isDeletingAnnotation = false
            self.annotationToDelete = nil
            self.showDeleteConfirmation = false
        }
    }
    
    // MARK: - Annotation Management

    /// Updates the size of all annotations when scale slider changes
    private func updateAllAnnotationScales() {
        for (node, _, _) in annotationNodes {
            node.scale = SCNVector3(annotationScale, annotationScale, annotationScale)
        }
    }

    /// Pauses the AR session and stops object detection
    func pauseARSession() {
        isDetectionActive = false
        detectedObjectName = ""
        
        if let sceneView = sceneView {
            sceneView.session.pause()
            sessionState = .paused
        }
    }

    /// Restarts the AR session with fresh configuration
    /// Resets tracking and anchors for a clean state
    func resumeARSession() {
        guard let sceneView = sceneView else { return }
        
        // Ensure session is paused before restarting
        if sessionState != .paused {
            sceneView.session.pause()
            sessionState = .paused
        }
        
        // Small delay before restarting for better stability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sceneView.backgroundColor = .black
            
            // Configure AR with plane detection and environment texturing
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            
            // Enable mesh reconstruction if device supports it (LiDAR)
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }
            
            // Smooth transition when restarting session
            UIView.transition(with: sceneView, duration: 0.3, options: .transitionCrossDissolve) {
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
            }
            
            self.sessionState = .active
        }
    }
    
    /// Adds a new annotation at the center of the detection box
    /// Uses raycasting to find a plane to anchor it to
    func addAnnotation() {
        
        // Prevent multiple simultaneous adds
        guard !isAddingAnnotation else { return }
        
        // Only add if we have a valid object name
        guard !detectedObjectName.isEmpty,
              !detectedObjectName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Make sure AR is ready
        guard let sceneView = sceneView,
              sceneView.session.currentFrame != nil else { return }
        
        isAddingAnnotation = true
        
        // Use center of the yellow box as placement point
        let roiCenter = CGPoint(x: adjustableROI.midX, y: adjustableROI.midY)
        
        // Try to find a plane at that point using raycasting
        if let query = sceneView.raycastQuery(from: roiCenter, allowing: .estimatedPlane, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let result = results.first {
                DispatchQueue.main.async {
                    
                    // Double-check object name is still valid
                    guard !self.detectedObjectName.isEmpty else {
                        self.isAddingAnnotation = false
                        return
                    }
                    
                    // Create annotation and add to scene
                    let annotationNode = self.createCapsuleAnnotation(with: self.detectedObjectName)
                    annotationNode.simdTransform = result.worldTransform
                    annotationNode.scale = SCNVector3(self.annotationScale, self.annotationScale, self.annotationScale)
                    
                    // Store world position for later reference
                    let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x,
                                               result.worldTransform.columns.3.y,
                                               result.worldTransform.columns.3.z)
                    self.annotationNodes.append((annotationNode, self.detectedObjectName, worldPos))
                    sceneView.scene.rootNode.addChildNode(annotationNode)
                    
                    // Reset state after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isAddingAnnotation = false
                    }
                }
            } else {
                
                // No plane found - show placement error
                DispatchQueue.main.async {
                    self.showPlacementError = true
                    self.isAddingAnnotation = false
                    
                    // Hide error after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showPlacementError = false
                    }
                }
            }
        } else {
            // Couldn't create raycast query
            DispatchQueue.main.async {
                self.isAddingAnnotation = false
            }
        }
    }
    
    /// Removes all annotations from the scene
    func resetAnnotations() {
        for (node, _, _) in annotationNodes {
            node.removeFromParentNode()
        }
        annotationNodes.removeAll()
    }
    
    // MARK: - Annotation Visuals

    /// Creates a capsule-shaped annotation with text
    /// Uses SpriteKit for text rendering inside SceneKit
    private func createCapsuleAnnotation(with text: String) -> SCNNode {
        let validatedText = text.isEmpty ? "Unknown Object" : text

        // Size calculations based on text length
        let baseWidth: CGFloat = 0.18
        let extraWidthPerChar: CGFloat = 0.005
        let maxTextWidth: CGFloat = 0.40
        let minTextWidth: CGFloat = 0.18
        let planeHeight: CGFloat = 0.09
        
        // Adjust width based on text length with min/max constraints
        let textCount = CGFloat(validatedText.count)
        let planeWidth = min(max(baseWidth + textCount * extraWidthPerChar, minTextWidth),
                             maxTextWidth)
        
        // Create a plane with rounded corners
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.cornerRadius = 0.015
        
        // Use SpriteKit scene for the plane's contents
        plane.firstMaterial?.diffuse.contents = makeCapsuleSKScene(with: validatedText, width: planeWidth, height: planeHeight)
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
        planeNode.position = SCNVector3(0, 0.04, 0)
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
    /// Handles text layout, background capsule, and styling
    private func makeCapsuleSKScene(with text: String, width: CGFloat, height: CGFloat) -> SKScene {
        let sceneSize = CGSize(width: 400, height: 140)
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        
        // Create white capsule background
        let bgRect = CGRect(origin: .zero, size: sceneSize)
        let background = SKShapeNode(rect: bgRect, cornerRadius: 50)
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
        chevron.fontSize = 36
        chevron.fontColor = .gray
        chevron.verticalAlignmentMode = .center
        chevron.horizontalAlignmentMode = .center
        chevron.position = CGPoint(x: sceneSize.width - 40, y: -sceneSize.height / 2)
        containerNode.addChild(chevron)
        
        // Process text into lines that fit the capsule
        let processedLines = processTextIntoLines(text, maxCharsPerLine: 20)
        let lineHeight: CGFloat = 40
        let totalTextHeight = CGFloat(processedLines.count) * lineHeight
        let startY = (sceneSize.height + totalTextHeight) / 2 - lineHeight / 2
        
        // Add each line of text
        for (i, line) in processedLines.enumerated() {
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.text = line
            label.fontSize = 32
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            
            let yPosition = startY - (CGFloat(i) * lineHeight)
            label.position = CGPoint(
                x: (sceneSize.width - 40) / 2,
                y: -yPosition
            )
            containerNode.addChild(label)
        }
        
        return scene
    }
    
    /// Handles text wrapping for annotation labels
    /// Splits text into lines and adds ellipsis for overflow
    private func processTextIntoLines(_ text: String, maxCharsPerLine: Int) -> [String] {
        var lines = [String]()
        var words = text.split(separator: " ").map(String.init)
        var currentLine = ""
        
        let ellipsis = "..."
        
        // Process words into lines with max 2 lines total
        while !words.isEmpty && lines.count < 2 {
            let word = words[0]
            let testLine = currentLine.isEmpty ? word : currentLine + " " + word
            
            if testLine.count <= maxCharsPerLine {
                
                // Word fits on current line
                currentLine = testLine
                words.removeFirst()
            } else {
                
                // Word doesn't fit - handle overflow
                if lines.count == 1 {
                    
                    // On second line - add ellipsis and stop
                    if !currentLine.isEmpty {
                        currentLine = currentLine.trimmingCharacters(in: .whitespaces)
                        if currentLine.count > maxCharsPerLine - ellipsis.count {
                            currentLine = String(currentLine.prefix(maxCharsPerLine - ellipsis.count)) + ellipsis
                        } else {
                            currentLine += ellipsis
                        }
                    }
                    break
                } else {
                    
                    // On first line - start new line or truncate
                    if !currentLine.isEmpty {
                        lines.append(currentLine)
                        currentLine = ""
                    } else {
                        currentLine = String(word.prefix(maxCharsPerLine))
                        words.removeFirst()
                    }
                }
            }
        }
        
        // Add final line if not empty
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        // Add ellipsis to last line if we have more words
        if !words.isEmpty && lines.count <= 2 {
            let lastIndex = lines.count - 1
            var lastLine = lines[lastIndex]
            if lastLine.count > maxCharsPerLine - ellipsis.count {
                lastLine = String(lastLine.prefix(maxCharsPerLine - ellipsis.count)) + ellipsis
            } else {
                lastLine += ellipsis
            }
            lines[lastIndex] = lastLine
        }
        
        // Reverse order because SpriteKit's coordinate system is different
        return lines.reversed()
    }
}

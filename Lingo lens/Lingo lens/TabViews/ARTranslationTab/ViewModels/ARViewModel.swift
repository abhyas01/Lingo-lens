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

    // Detection mode: objects or text
    enum DetectionMode {
        case objects
        case text
    }

    // MARK: - Published States

    // Current detection mode (objects or text)
    @Published var detectionMode: DetectionMode = .objects

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
    @Published var placementErrorMessage = "Couldn't anchor label on object. Try adjusting your angle or moving closer to help detect a surface."
    
    // Controls delete confirmation alert
    @Published var showDeleteConfirmation = false
    
    // Tracks which annotation is being deleted
    @Published var annotationToDelete: Int? = nil
    
    // Name of the annotation being deleted (shown in alert)
    @Published var annotationNameToDelete: String = ""
    
    // Tracks whether deletion is in progress
    @Published var isDeletingAnnotation = false
    
    // Tracks if AR is setting up
    @Published var isARSessionLoading: Bool = true

    // Current user-facing message explaining AR session status
    @Published var loadingMessage: String = "Setting up AR session..."

    // Text recognition results
    @Published var recognizedTexts: [RecognizedTextItem] = []

    // Text overlay nodes for AR scene
    var textOverlayNodes: [(node: SCNNode, textItem: RecognizedTextItem)] = []
    
    // Currently selected language for translations
    // Persists to UserDefaults when changed
    @Published var selectedLanguage: AvailableLanguage {
        didSet {
            print("🌐 Selected language changed to: \(selectedLanguage.shortName())")
            DataManager.shared.saveSelectedLanguageCode(selectedLanguage.shortName())
        }
    }
    
    // Scale factor for annotation size
    // Persists to UserDefaults when changed
    @Published var annotationScale: CGFloat = DataManager.shared.getAnnotationScale() {
        didSet {
            print("Annotation size slider updated to: \(annotationScale)")
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
        guard let index = annotationToDelete, index < annotationNodes.count else {
            print("⚠️ Invalid annotation index for deletion: \(String(describing: annotationToDelete))")
            return
        }
        
        print("🗑️ Deleting annotation at index \(index)")
        isDeletingAnnotation = true
        
        // Small delay to show deletion is happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Get the annotation and remove from scene
            let (node, _, _) = self.annotationNodes[index]
            print("🗑️ Removing annotation from scene")
            node.removeFromParentNode()
            
            // Remove from our tracking array
            self.annotationNodes.remove(at: index)
            print("✅ Annotation deleted successfully - \(self.annotationNodes.count) annotations remaining")
            
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
        print("⏸️ Pausing AR session")
        isDetectionActive = false
        detectedObjectName = ""
        
        if let sceneView = sceneView {
            sceneView.session.pause()
            sessionState = .paused
            print("✅ AR session paused")
        }
    }

    /// Restarts the AR session with fresh configuration
    /// Resets tracking and anchors for a clean state
    func resumeARSession() {
        guard let sceneView = sceneView else { return }
        
        print("▶️ Resuming AR session")
        
        // Reset AR loading state
        isARSessionLoading = true
        
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
        guard !isAddingAnnotation else {
            print("⚠️ Already adding an annotation - ignoring request")
            return
        }
        
        // Only add if we have a valid object name
        guard !detectedObjectName.isEmpty,
              !detectedObjectName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("⚠️ Cannot add annotation - no object detected")
            return
        }
        
        // Make sure AR is ready
        guard let sceneView = sceneView,
              sceneView.session.currentFrame != nil else { return }
        
        print("➕ Adding annotation for object: \"\(detectedObjectName)\"")
        isAddingAnnotation = true
        
        // Use center of the yellow box as placement point
        let roiCenter = CGPoint(x: adjustableROI.midX, y: adjustableROI.midY)
        print("📍 Attempting to place annotation at screen position: \(roiCenter)")
        
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
                    self.isAddingAnnotation = false
                    
                    if !self.showPlacementError {
                        self.showPlacementError = true
                        
                        // Hide error after 4 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            self.showPlacementError = false
                        }
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
        print("🧹 Clearing all annotations - count before reset: \(annotationNodes.count)")
        for (node, _, _) in annotationNodes {
            node.removeFromParentNode()
        }
        annotationNodes.removeAll()
        print("✅ All annotations cleared")
    }

    // MARK: - Text Overlay Management

    /// Creates AR text overlays for recognized text items
    func createTextOverlays(for items: [RecognizedTextItem], in sceneView: ARSCNView) {
        // Remove old overlays
        clearTextOverlays()

        for item in items {
            guard item.meetsConfidenceThreshold else { continue }

            // Create text overlay node
            if let overlayNode = createTextOverlayNode(for: item, in: sceneView) {
                sceneView.scene.rootNode.addChildNode(overlayNode)

                // Store reference
                var updatedItem = item
                updatedItem.worldPosition = overlayNode.worldPosition
                textOverlayNodes.append((node: overlayNode, textItem: updatedItem))
            }
        }
    }

    /// Clears all text overlay nodes
    func clearTextOverlays() {
        for (node, _) in textOverlayNodes {
            node.removeFromParentNode()
        }
        textOverlayNodes.removeAll()
    }

    /// Creates a text overlay node anchored to detected text
    private func createTextOverlayNode(for item: RecognizedTextItem, in sceneView: ARSCNView) -> SCNNode? {
        guard let frame = sceneView.session.currentFrame else { return nil }

        // Convert normalized bounding box to screen coordinates
        let viewSize = sceneView.bounds.size
        let screenRect = CGRect(
            x: item.boundingBox.origin.x * viewSize.width,
            y: (1 - item.boundingBox.origin.y - item.boundingBox.height) * viewSize.height,
            width: item.boundingBox.width * viewSize.width,
            height: item.boundingBox.height * viewSize.height
        )

        // Get center point of text
        let centerPoint = CGPoint(x: screenRect.midX, y: screenRect.midY)

        // Perform robust raycasting to find a position in 3D space
        if let worldPosition = performRobustRaycast(from: centerPoint, in: sceneView) {
            // Create the overlay node
            let node = createStabilizedTextNode(
                text: item.translatedText ?? item.text,
                fontSize: calculateFontSize(for: item, in: sceneView),
                at: worldPosition
            )

            return node
        }

        return nil
    }

    /// Performs robust raycasting with multiple fallback strategies
    private func performRobustRaycast(from point: CGPoint, in sceneView: ARSCNView) -> SCNVector3? {
        // Strategy 1: Try existing planes
        if let query = sceneView.raycastQuery(from: point, allowing: .existingPlaneGeometry, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let result = results.first {
                return SCNVector3(result.worldTransform.columns.3.x,
                                result.worldTransform.columns.3.y,
                                result.worldTransform.columns.3.z)
            }
        }

        // Strategy 2: Try estimated planes
        if let query = sceneView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let result = results.first {
                return SCNVector3(result.worldTransform.columns.3.x,
                                result.worldTransform.columns.3.y,
                                result.worldTransform.columns.3.z)
            }
        }

        // Strategy 3: Use hit test on feature points
        let hitResults = sceneView.hitTest(point, types: [.featurePoint])
        if let result = hitResults.first {
            return SCNVector3(result.worldTransform.columns.3.x,
                            result.worldTransform.columns.3.y,
                            result.worldTransform.columns.3.z)
        }

        // Strategy 4: Project at fixed distance
        guard let frame = sceneView.session.currentFrame else { return nil }
        let camera = frame.camera
        let viewMatrix = camera.viewMatrix(for: .portrait)
        let projectionMatrix = camera.projectionMatrix(for: .portrait, viewportSize: sceneView.bounds.size, zNear: 0.001, zFar: 1000)

        // Unproject point to 3D space at 0.5m distance
        let normalizedPoint = CGPoint(
            x: (point.x / sceneView.bounds.width) * 2 - 1,
            y: -((point.y / sceneView.bounds.height) * 2 - 1)
        )

        let nearPoint = simd_float4(Float(normalizedPoint.x), Float(normalizedPoint.y), -1, 1)
        let farPoint = simd_float4(Float(normalizedPoint.x), Float(normalizedPoint.y), 1, 1)

        let inverseProjection = projectionMatrix.inverse
        let inverseView = viewMatrix.inverse

        let nearWorld = inverseView * (inverseProjection * nearPoint)
        let farWorld = inverseView * (inverseProjection * farPoint)

        let nearWorldNormalized = simd_float3(nearWorld.x / nearWorld.w, nearWorld.y / nearWorld.w, nearWorld.z / nearWorld.w)
        let farWorldNormalized = simd_float3(farWorld.x / farWorld.w, farWorld.y / farWorld.w, farWorld.z / farWorld.w)

        let direction = simd_normalize(farWorldNormalized - nearWorldNormalized)
        let distance: Float = 0.5 // 50cm from camera

        let worldPos = nearWorldNormalized + direction * distance

        return SCNVector3(worldPos.x, worldPos.y, worldPos.z)
    }

    /// Creates a stabilized text node with proper constraints
    private func createStabilizedTextNode(text: String, fontSize: CGFloat, at position: SCNVector3) -> SCNNode {
        // Create text geometry
        let textGeometry = SCNText(string: text, extrusionDepth: 0.5)
        textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        textGeometry.flatness = 0.1
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.5)
        textGeometry.firstMaterial?.isDoubleSided = true

        // Create node
        let textNode = SCNNode(geometry: textGeometry)

        // Center the text
        let (min, max) = textNode.boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)

        // Create container with background
        let containerNode = SCNNode()

        // Add semi-transparent background
        let backgroundWidth = (max.x - min.x) * 1.1
        let backgroundHeight = (max.y - min.y) * 1.3
        let backgroundPlane = SCNPlane(width: CGFloat(backgroundWidth), height: CGFloat(backgroundHeight))
        backgroundPlane.cornerRadius = CGFloat(backgroundHeight) * 0.1
        backgroundPlane.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.7)
        backgroundPlane.firstMaterial?.isDoubleSided = true

        let backgroundNode = SCNNode(geometry: backgroundPlane)
        backgroundNode.position = SCNVector3(0, 0, -0.01)

        containerNode.addChildNode(backgroundNode)
        containerNode.addChildNode(textNode)

        // Position in world
        containerNode.position = position

        // Add billboard constraint (always face camera)
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.X, .Y, .Z]
        containerNode.constraints = [billboardConstraint]

        // Scale appropriately (text is in points, need to convert to meters)
        let scale: Float = 0.001
        containerNode.scale = SCNVector3(scale, scale, scale)

        return containerNode
    }

    /// Calculates appropriate font size based on text bounding box
    private func calculateFontSize(for item: RecognizedTextItem, in sceneView: ARSCNView) -> CGFloat {
        let viewSize = sceneView.bounds.size
        let textHeight = item.boundingBox.height * viewSize.height

        // Map screen height to font size (empirically determined)
        let baseFontSize: CGFloat = 200
        let scaleFactor = textHeight / 20.0
        return baseFontSize * max(0.5, min(scaleFactor, 3.0))
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

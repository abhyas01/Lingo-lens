//
//  ARViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit
import UIKit

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
    
    // Tracks if AR is setting up
    @Published var isARSessionLoading: Bool = true

    // Current user-facing message explaining AR session status
    @Published var loadingMessage: String = "Setting up AR session..."

    // Text recognition results
    @Published var recognizedTexts: [RecognizedTextItem] = []

    // Text overlay nodes for AR scene
    var textOverlayNodes: [(node: SCNNode, textItem: RecognizedTextItem)] = []

    // Instant OCR mode - full-screen detection without yellow box
    @Published var instantOCRMode: Bool = false
    
    // Currently selected language for translations
    // Persists to UserDefaults when changed
    @Published var selectedLanguage: AvailableLanguage {
        didSet {
            Logger.info("Selected language changed to: \(selectedLanguage.shortName())")
            DataManager.shared.saveSelectedLanguageCode(selectedLanguage.shortName())
        }
    }
    
    // Scale factor for annotation size
    // Persists to UserDefaults when changed
    @Published var annotationScale: CGFloat = DataManager.shared.getAnnotationScale() {
        didSet {
            Logger.debug("Annotation size slider updated to: \(annotationScale)")
            DataManager.shared.saveAnnotationScale(annotationScale)
            annotationManager.updateAllAnnotationScales(annotationScale)
        }
    }

    // MARK: - Properties

    // Reference to AR scene view (set by ARViewContainer)
    weak var sceneView: ARSCNView?

    // Manages all annotation-related functionality
    let annotationManager = AnnotationManager()
    
    
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
        } else if let firstLanguage = availableLanguages.first {

            // Default to first available language if saved one isn't available
            self.selectedLanguage = firstLanguage
            DataManager.shared.saveSelectedLanguageCode(selectedLanguage.shortName())
        }
    }

    /// Shows delete confirmation alert for an annotation
    /// Delegates to AnnotationManager
    func showDeleteAnnotationAlert(index: Int, objectName: String) {
        annotationManager.showDeleteAnnotationAlert(index: index, objectName: objectName)
    }

    /// Removes an annotation from the AR scene
    /// Delegates to AnnotationManager
    func deleteAnnotation() {
        annotationManager.deleteAnnotation()
    }

    // MARK: - Annotation Management

    /// Pauses the AR session and stops object detection
    func pauseARSession() {
        Logger.info(" Pausing AR session")
        isDetectionActive = false
        detectedObjectName = ""
        
        if let sceneView = sceneView {
            sceneView.session.pause()
            sessionState = .paused
            Logger.info(" AR session paused")
        }
    }

    /// Restarts the AR session with fresh configuration
    /// Resets tracking and anchors for a clean state
    func resumeARSession() {
        guard let sceneView = sceneView else { return }
        
        Logger.info(" Resuming AR session")
        
        // Reset AR loading state
        isARSessionLoading = true
        
        // Ensure session is paused before restarting
        if sessionState != .paused {
            sceneView.session.pause()
            sessionState = .paused
        }
        
        // Small delay before restarting for better stability
        DispatchQueue.main.asyncAfter(deadline: .now() + ARConstants.annotationAddDelay) {
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
            UIView.transition(with: sceneView, duration: ARConstants.sessionTransitionDuration, options: .transitionCrossDissolve) {
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
            }
            
            self.sessionState = .active
        }
    }
    
    /// Adds a new annotation at the center of the detection box
    /// Uses raycasting to find a plane to anchor it to
    func addAnnotation() {
        // Delegate to AnnotationManager
        annotationManager.addAnnotation(objectName: detectedObjectName, at: adjustableROI)
    }

    /// Removes all annotations from the scene
    func resetAnnotations() {
        // Delegate to AnnotationManager
        annotationManager.resetAnnotations()
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
        let projectionMatrix = camera.projectionMatrix(for: .portrait, viewportSize: sceneView.bounds.size, zNear: ARConstants.cameraZNear, zFar: ARConstants.cameraZFar)

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
    /// Now with orientation-locked overlays that truly replace text
    private func createStabilizedTextNode(text: String, fontSize: CGFloat, at position: SCNVector3) -> SCNNode {
        // Use SpriteKit for better text rendering
        let labelNode = SKLabelNode(text: text)
        labelNode.fontName = "Helvetica-Bold"
        labelNode.fontSize = fontSize
        labelNode.fontColor = .white
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center

        // Calculate size
        let textSize = labelNode.frame.size
        let padding: CGFloat = ARConstants.textOverlayPadding

        // Create background with rounded corners
        let backgroundSize = CGSize(
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )

        let scene = SKScene(size: backgroundSize)
        scene.backgroundColor = .clear

        // Add semi-transparent black background
        let background = SKShapeNode(rectOf: backgroundSize, cornerRadius: backgroundSize.height * ARConstants.textOverlayCornerRadiusRatio)
        background.fillColor = UIColor.black.withAlphaComponent(ARConstants.textOverlayBackgroundAlpha)
        background.strokeColor = .clear
        background.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
        scene.addChild(background)

        // Add text on top
        labelNode.position = CGPoint(x: backgroundSize.width / 2, y: backgroundSize.height / 2)
        scene.addChild(labelNode)

        // Create plane to display the sprite
        let aspectRatio = backgroundSize.width / backgroundSize.height
        let planeHeight: CGFloat = ARConstants.textOverlayPlaneHeight height
        let planeWidth = planeHeight * aspectRatio

        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.firstMaterial?.diffuse.contents = scene
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.lightingModel = .constant  // No lighting effects

        // Create node
        let textNode = SCNNode(geometry: plane)
        textNode.position = position

        // IMPROVED: Use look-at constraint for better orientation
        // This makes text face camera but locks to surface when possible
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.Y]  // Only rotate around Y axis (keeps text upright)
        textNode.constraints = [billboardConstraint]

        // Add subtle glow effect
        plane.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(ARConstants.textOverlayEmissionAlpha)

        return textNode
    }

    /// Calculates appropriate font size based on text bounding box
    private func calculateFontSize(for item: RecognizedTextItem, in sceneView: ARSCNView) -> CGFloat {
        let viewSize = sceneView.bounds.size
        let textHeight = item.boundingBox.height * viewSize.height

        // Map screen height to font size (empirically determined)
        let baseFontSize = ARConstants.baseFontSize
        let scaleFactor = textHeight / ARConstants.fontSizeHeightDivisor
        return baseFontSize * max(ARConstants.minFontSizeScale, min(scaleFactor, ARConstants.maxFontSizeScale))
    }
}

//
//  ARViewModel.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit
import SceneKit

class ARViewModel: ObservableObject {
    @Published var detectedObjectName: String = ""
    @Published var adjustableROI: CGRect = .zero
    @Published var annotationScale: CGFloat = 1.0 {
        didSet {
            updateAllAnnotationScales()
        }
    }

    weak var sceneView: ARSCNView?
    private var annotationNodes: [SCNNode] = []  // Track all annotation nodes

    private func updateAllAnnotationScales() {
        for node in annotationNodes {
            // Apply new scale while maintaining aspect ratio
            node.scale = SCNVector3(annotationScale, annotationScale, annotationScale)
        }
    }

    func addAnnotation() {
        guard !detectedObjectName.isEmpty else { return }
        guard let sceneView = sceneView,
              let _ = sceneView.session.currentFrame else { return }

        // Raycast from the center of the adjustable ROI
        let roiCenter = CGPoint(x: adjustableROI.midX, y: adjustableROI.midY)
        
        if let query = sceneView.raycastQuery(from: roiCenter, allowing: .estimatedPlane, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let result = results.first {
                // Create annotation node
                let annotationNode = createCapsuleAnnotation(with: detectedObjectName)
                
                // Create anchor and add it to the session
                let anchor = ARAnchor(transform: result.worldTransform)
                sceneView.session.add(anchor: anchor)
                
                // Set the node's transform to match the anchor
                annotationNode.simdTransform = result.worldTransform
                
                annotationNode.scale = SCNVector3(annotationScale, annotationScale, annotationScale)
                
                // Add to tracking array
                annotationNodes.append(annotationNode)
                
                // Add to the scene
                sceneView.scene.rootNode.addChildNode(annotationNode)
            }
        }
    }

    // Reset annotations (useful when changing scenes or restarting)
    func resetAnnotations() {
        for node in annotationNodes {
            node.removeFromParentNode()
        }
        annotationNodes.removeAll()
    }

    private func createCapsuleAnnotation(with text: String) -> SCNNode {
        // Base dimensions with extra space for chevron
        let baseWidth: CGFloat = 0.18  // Reduced base width
        let extraWidthPerChar: CGFloat = 0.005
        let maxTextWidth: CGFloat = 0.40  // Reduced max width
        let minTextWidth: CGFloat = 0.18
        let planeHeight: CGFloat = 0.09  // Reduced height
        
        let textCount = CGFloat(text.count)
        let planeWidth = min(max(baseWidth + textCount * extraWidthPerChar, minTextWidth),
                             maxTextWidth)
        
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.cornerRadius = 0.015
        
        plane.firstMaterial?.diffuse.contents = makeCapsuleSKScene(with: text, width: planeWidth, height: planeHeight)
        plane.firstMaterial?.isDoubleSided = true
        
        let planeNode = SCNNode(geometry: plane)
        let containerNode = SCNNode()
        containerNode.addChildNode(planeNode)
        planeNode.position = SCNVector3(0, 0.04, 0)
        containerNode.eulerAngles.x = -Float.pi / 2
        
        // Apply scale from slider
        containerNode.scale = SCNVector3(annotationScale, annotationScale, annotationScale)
        
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        containerNode.constraints = [billboard]
        
        return containerNode
    }
    
    private func makeCapsuleSKScene(with text: String, width: CGFloat, height: CGFloat) -> SKScene {
        let sceneSize = CGSize(width: 400, height: 140)
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        
        // Background
        let bgRect = CGRect(origin: .zero, size: sceneSize)
        let background = SKShapeNode(rect: bgRect, cornerRadius: 50)
        background.fillColor = .white
        background.strokeColor = .clear
        scene.addChild(background)
        
        // Container for flipped content
        let containerNode = SKNode()
        containerNode.setScale(1.0)
        containerNode.yScale = -1
        scene.addChild(containerNode)
        
        // Add chevron indicator
        let chevron = SKLabelNode(fontNamed: "SF Pro")
        chevron.text = "›"
        chevron.fontSize = 36
        chevron.fontColor = .gray
        chevron.verticalAlignmentMode = .center
        chevron.horizontalAlignmentMode = .center
        chevron.position = CGPoint(x: sceneSize.width - 40, y: -sceneSize.height/2)
        containerNode.addChild(chevron)
        
        // Process text with max characters and line limit
        let processedLines = processTextIntoLines(text, maxCharsPerLine: 20)
        let lineHeight: CGFloat = 40
        let totalTextHeight = CGFloat(processedLines.count) * lineHeight
        let startY = (sceneSize.height + totalTextHeight) / 2 - lineHeight / 2
        
        // Add text lines
        for (i, line) in processedLines.enumerated() {
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.text = line
            label.fontSize = 32  // Consistent font size
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            
            let yPosition = startY - (CGFloat(i) * lineHeight)
            label.position = CGPoint(
                x: (sceneSize.width - 40) / 2,  // Shifted left to account for chevron
                y: -yPosition
            )
            containerNode.addChild(label)
        }
        
        return scene
    }

    private func processTextIntoLines(_ text: String, maxCharsPerLine: Int) -> [String] {
        var lines = [String]()
        var words = text.split(separator: " ").map(String.init)
        var currentLine = ""
        
        let ellipsis = "..."  // Define ellipsis constant
        
        // Only process up to 2 lines
        while !words.isEmpty && lines.count < 2 {
            let word = words[0]
            let testLine = currentLine.isEmpty ? word : currentLine + " " + word
            
            if testLine.count <= maxCharsPerLine {
                currentLine = testLine
                words.removeFirst()
            } else {
                // If this is the last allowed line and we have more words
                if lines.count == 1 {
                    // Add ellipsis to the current line if it's not empty
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
        
        // Add the last line if we have one
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        // If we still have words left and we're under 2 lines, add ellipsis
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
        
        return lines.reversed()
    }
}

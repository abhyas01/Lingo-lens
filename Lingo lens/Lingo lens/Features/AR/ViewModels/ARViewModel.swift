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
    @Published var isDetectionActive = false
    @Published var detectedObjectName: String = ""
    @Published var adjustableROI: CGRect = .zero
    @Published var selectedAnnotationText: String?
    @Published var isShowingAnnotationDetail: Bool = false
    @Published var annotationScale: CGFloat = 1.0 {
        didSet {
            updateAllAnnotationScales()
        }
    }
    @Published var selectedLanguage: AvailableLanguage = AvailableLanguage(locale: Locale.Language(languageCode: "es", region: "ES"))
    
    weak var sceneView: ARSCNView?
    
    var annotationNodes: [(node: SCNNode, originalText: String, worldPos: SIMD3<Float>)] = []

    private func updateAllAnnotationScales() {
        for (node, _, _) in annotationNodes {
            node.scale = SCNVector3(annotationScale, annotationScale, annotationScale)
        }
    }

    func addAnnotation() {
        guard !detectedObjectName.isEmpty,
              !detectedObjectName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        guard let sceneView = sceneView,
              sceneView.session.currentFrame != nil else { return }
        
        let roiCenter = CGPoint(x: adjustableROI.midX, y: adjustableROI.midY)
        
        if let query = sceneView.raycastQuery(from: roiCenter, allowing: .estimatedPlane, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let result = results.first {
                DispatchQueue.main.async {
                    guard !self.detectedObjectName.isEmpty else { return }
                    
                    let annotationNode = self.createCapsuleAnnotation(with: self.detectedObjectName)
                    annotationNode.simdTransform = result.worldTransform
                    let worldPos = SIMD3<Float>(result.worldTransform.columns.3.x,
                                               result.worldTransform.columns.3.y,
                                               result.worldTransform.columns.3.z)
                    self.annotationNodes.append((annotationNode, self.detectedObjectName, worldPos))
                    sceneView.scene.rootNode.addChildNode(annotationNode)
                }
            }
        }
    }
    
    func resetAnnotations() {
        for (node, _, _) in annotationNodes {
            node.removeFromParentNode()
        }
        annotationNodes.removeAll()
    }

    private func createCapsuleAnnotation(with text: String) -> SCNNode {
        let validatedText = text.isEmpty ? "Unknown Object" : text

        let baseWidth: CGFloat = 0.18
        let extraWidthPerChar: CGFloat = 0.005
        let maxTextWidth: CGFloat = 0.40
        let minTextWidth: CGFloat = 0.18
        let planeHeight: CGFloat = 0.09
        
        let textCount = CGFloat(validatedText.count)
        let planeWidth = min(max(baseWidth + textCount * extraWidthPerChar, minTextWidth),
                             maxTextWidth)
        
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.cornerRadius = 0.015
        
        plane.firstMaterial?.diffuse.contents = makeCapsuleSKScene(with: validatedText, width: planeWidth, height: planeHeight)
        plane.firstMaterial?.isDoubleSided = true
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.name = "annotationPlane"
        planeNode.categoryBitMask = 1

        let containerNode = SCNNode()
        containerNode.name = "annotationContainer"
        containerNode.categoryBitMask = 1
        
        containerNode.addChildNode(planeNode)
        planeNode.position = SCNVector3(0, 0.04, 0)
        containerNode.eulerAngles.x = -Float.pi / 2
        
        containerNode.scale = SCNVector3(annotationScale, annotationScale, annotationScale)
        
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y, .Z]
        containerNode.constraints = [billboard]
        
        return containerNode
    }
    
    private func makeCapsuleSKScene(with text: String, width: CGFloat, height: CGFloat) -> SKScene {
        let sceneSize = CGSize(width: 400, height: 140)
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        
        let bgRect = CGRect(origin: .zero, size: sceneSize)
        let background = SKShapeNode(rect: bgRect, cornerRadius: 50)
        background.fillColor = .white
        background.strokeColor = .clear
        scene.addChild(background)
        
        let containerNode = SKNode()
        containerNode.setScale(1.0)
        containerNode.yScale = -1
        scene.addChild(containerNode)
        
        let chevron = SKLabelNode(fontNamed: "SF Pro")
        chevron.text = "›"
        chevron.fontSize = 36
        chevron.fontColor = .gray
        chevron.verticalAlignmentMode = .center
        chevron.horizontalAlignmentMode = .center
        chevron.position = CGPoint(x: sceneSize.width - 40, y: -sceneSize.height / 2)
        containerNode.addChild(chevron)
        
        let processedLines = processTextIntoLines(text, maxCharsPerLine: 20)
        let lineHeight: CGFloat = 40
        let totalTextHeight = CGFloat(processedLines.count) * lineHeight
        let startY = (sceneSize.height + totalTextHeight) / 2 - lineHeight / 2
        
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
    
    private func processTextIntoLines(_ text: String, maxCharsPerLine: Int) -> [String] {
        var lines = [String]()
        var words = text.split(separator: " ").map(String.init)
        var currentLine = ""
        
        let ellipsis = "..."
        
        while !words.isEmpty && lines.count < 2 {
            let word = words[0]
            let testLine = currentLine.isEmpty ? word : currentLine + " " + word
            
            if testLine.count <= maxCharsPerLine {
                currentLine = testLine
                words.removeFirst()
            } else {
                if lines.count == 1 {
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
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
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

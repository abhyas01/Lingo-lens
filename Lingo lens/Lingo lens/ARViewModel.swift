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

    weak var sceneView: ARSCNView?

    func addAnnotation() {
        guard !detectedObjectName.isEmpty else { return }
        guard let sceneView = sceneView,
              let currentFrame = sceneView.session.currentFrame else { return }

        // 1) Raycast from screen center
        let centerPoint = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        if let query = sceneView.raycastQuery(from: centerPoint, allowing: .estimatedPlane, alignment: .any) {
            let results = sceneView.session.raycast(query)
            if let closestResult = results.first {
                // 2) Convert transform -> position
                let transform = closestResult.worldTransform
                let position = SCNVector3(transform.columns.3.x,
                                          transform.columns.3.y,
                                          transform.columns.3.z)

                // 3) Create a parent node
                let parentNode = SCNNode()
                parentNode.position = position

                // 4) Create the annotation node
                let annotationNode = createCapsuleAnnotation(with: detectedObjectName)

                // 5) Add annotation as child
                parentNode.addChildNode(annotationNode)

                // 6) Add to the scene
                sceneView.scene.rootNode.addChildNode(parentNode)
            }
        }
    }

    private func createCapsuleAnnotation(with text: String) -> SCNNode {
        // 1) Dynamically size the plane
        let baseWidth: CGFloat = 0.16
        let extraWidthPerChar: CGFloat = 0.005
        let maxTextWidth: CGFloat = 0.40
        let minTextWidth: CGFloat = 0.16
        
        let textCount = CGFloat(text.count)
        let planeWidth = min(max(baseWidth + textCount * extraWidthPerChar, minTextWidth),
                             maxTextWidth)
        let planeHeight: CGFloat = 0.08
        
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.cornerRadius = 0.015
        
        // 2) Attach a normal SKScene (no inverted yScale).
        plane.firstMaterial?.diffuse.contents = makeCapsuleSKScene(with: text, width: planeWidth, height: planeHeight)
        plane.firstMaterial?.lightingModel = .constant
        plane.firstMaterial?.isDoubleSided = false  // Usually only need front side
        
        let planeNode = SCNNode(geometry: plane)
        
        // 3) If text is upside down, rotate around X:
        // planeNode.eulerAngles.x = .pi
        //
        // If text is mirrored left/right, rotate around Y:
        planeNode.eulerAngles.y = .pi
        
        // 4) Constrain so it faces camera horizontally
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        planeNode.constraints = [billboard]
        
        return planeNode
    }

    private func makeCapsuleSKScene(with text: String, width: CGFloat, height: CGFloat) -> SKScene {
        let sceneSize = CGSize(width: 400, height: 140)
        let scene = SKScene(size: sceneSize)
        scene.backgroundColor = .clear
        
        // 1) Rounded rectangle background (capsule style)
        let bgRect = CGRect(origin: .zero, size: sceneSize)
        let background = SKShapeNode(rect: bgRect, cornerRadius: 50)
        background.fillColor = .white
        background.strokeColor = .clear
        scene.addChild(background)
        
        // 2) Possibly break text into lines
        let lines = breakTextIntoLines(text, maxLineLen: 18)
        let lineHeight: CGFloat = 40
        let totalTextHeight = CGFloat(lines.count) * lineHeight
        let centerY = (sceneSize.height - totalTextHeight) / 2 + lineHeight / 2
        
        // 3) Add each line as SKLabelNode
        for (i, line) in lines.enumerated() {
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.text = line
            label.fontSize = lines.count > 3 ? 24 : (lines.count > 2 ? 30 : 36)
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: sceneSize.width / 2,
                                     y: centerY + CGFloat(lines.count - 1 - i) * lineHeight)
            scene.addChild(label)
        }
        
        return scene
    }


    private func breakTextIntoLines(_ text: String, maxLineLen: Int) -> [String] {
        var lines = [String]()
        var currentLine = ""
        for word in text.split(separator: " ") {
            let candidate = currentLine.isEmpty ? String(word)
                                                : currentLine + " " + word
            if candidate.count > maxLineLen {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                currentLine = String(word)
            } else {
                currentLine = candidate
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        return lines
    }
}

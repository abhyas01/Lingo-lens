//
//  AdjustableBoundingBox.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

/// Custom draggable and resizable bounding box for object detection
/// Box stays within camera view bounds and maintains minimum detection area
struct AdjustableBoundingBox: View {
    @Binding var roi: CGRect
    @State private var initialBoxROI: CGRect? = nil
    @State private var boxDragOffset: CGSize = .zero
    @State private var initialHandleROI: CGRect? = nil
    
    /// Min space between box edge and screen edge
    private let margin: CGFloat = 16
    private let minBoxSize: CGFloat = 100
    
    /// Positions for middle drag handles on each edge
    private enum EdgePosition: String {
        case top = "Top"
        case bottom = "Bottom"
        case leading = "Left"
        case trailing = "Right"
    }
    
    /// Positions for corner resize handles
    enum HandlePosition: String {
        case topLeft = "Top left"
        case topRight = "Top right"
        case bottomLeft = "Bottom left"
        case bottomRight = "Bottom right"
    }
    
    /// Size of the AR camera view for bounds checking
    var containerSize: CGSize
    
    // MARK: - Main Box Layout

    var body: some View {
        ZStack {
            
            Rectangle()
                .stroke(Color.yellow, lineWidth: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Detection box")
                .accessibilityHint("Area where objects will be detected")
                .background(Color.clear)
                .frame(width: roi.width, height: roi.height)
                .position(
                    x: roi.midX + boxDragOffset.width,
                    y: roi.midY + boxDragOffset.height
                )
                .gesture(mainDragGesture)
            
            handleView(for: .topLeft)
            handleView(for: .topRight)
            handleView(for: .bottomLeft)
            handleView(for: .bottomRight)
            
            edgeHandleView(for: .top)
            edgeHandleView(for: .bottom)
            edgeHandleView(for: .leading)
            edgeHandleView(for: .trailing)
        }
        .contentShape(CombinedContentShape(roi: roi, containerSize: containerSize, boxDragOffset: boxDragOffset))
        .allowsHitTesting(true)
    }
    
    // MARK: - Edge Handle Controls

    /// Creates a grabber icon for dragging entire box from any edge
    private func edgeHandleView(for position: EdgePosition) -> some View {
        Image(systemName: "square.arrowtriangle.4.outward")
            .font(.system(size: 25))
            .foregroundColor(Color.yellow)
            .position(edgePosition(for: position))
            .gesture(mainDragGesture)
            .accessibilityLabel("\(position.rawValue) edge")
            .accessibilityHint("Drag to move the detection box")
    }
    
    /// Gets screen position for edge handles based on current box location
    private func edgePosition(for position: EdgePosition) -> CGPoint {
        switch position {
        case .top:
            return CGPoint(x: roi.midX + boxDragOffset.width, y: roi.minY + boxDragOffset.height)
        case .bottom:
            return CGPoint(x: roi.midX + boxDragOffset.width, y: roi.maxY + boxDragOffset.height)
        case .leading:
            return CGPoint(x: roi.minX + boxDragOffset.width, y: roi.midY + boxDragOffset.height)
        case .trailing:
            return CGPoint(x: roi.maxX + boxDragOffset.width, y: roi.midY + boxDragOffset.height)
        }
    }
    
    // MARK: - Box Movement
    
    /// Core drag gesture for moving the entire box within screen bounds
    private var mainDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if initialBoxROI == nil {
                    initialBoxROI = roi
                }
                var translation = value.translation
                if let initial = initialBoxROI {
                    if translation.width > 0 {
                        let containerWidth = containerSize.width
                        let maxRightTranslation = containerWidth - margin - (initial.origin.x + initial.width)
                        translation.width = min(translation.width, maxRightTranslation)
                    }
                    if translation.width < 0 {
                        let maxLeftTranslation = margin - initial.origin.x
                        translation.width = max(translation.width, maxLeftTranslation)
                    }
                    if translation.height < 0 {
                        let maxUpTranslation = margin - initial.origin.y
                        translation.height = max(translation.height, maxUpTranslation)
                    }
                    if translation.height > 0 {
                        let containerHeight = containerSize.height
                        let maxDownTranslation = containerHeight - margin - (initial.origin.y + initial.height)
                        translation.height = min(translation.height, maxDownTranslation)
                    }
                }
                boxDragOffset = translation
            }
            .onEnded { value in
                if let initial = initialBoxROI {
                    var translation = value.translation
                    if translation.width > 0 {
                        let containerWidth = containerSize.width
                        let maxRightTranslation = containerWidth - margin - (initial.origin.x + initial.width)
                        translation.width = min(translation.width, maxRightTranslation)
                    }
                    if translation.width < 0 {
                        let maxLeftTranslation = margin - initial.origin.x
                        translation.width = max(translation.width, maxLeftTranslation)
                    }
                    if translation.height < 0 {
                        let maxUpTranslation = margin - initial.origin.y
                        translation.height = max(translation.height, maxUpTranslation)
                    }
                    if translation.height > 0 {
                        let containerHeight = containerSize.height
                        let maxDownTranslation = containerHeight - margin - (initial.origin.y + initial.height)
                        translation.height = min(translation.height, maxDownTranslation)
                    }
                    let newROI = CGRect(
                        x: initial.origin.x + translation.width,
                        y: initial.origin.y + translation.height,
                        width: initial.width,
                        height: initial.height
                    )
                    roi = clampROI(newROI)
                }
                initialBoxROI = nil
                boxDragOffset = .zero
            }
    }
    
    // MARK: - Corner Resizing

    /// Creates draggable circles at corners for resizing box
    @ViewBuilder
    private func handleView(for position: HandlePosition) -> some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 30, height: 30)
            .position(
                x: handlePosition(for: position).x + boxDragOffset.width,
                y: handlePosition(for: position).y + boxDragOffset.height
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if initialHandleROI == nil {
                            initialHandleROI = roi
                        }
                        let initial = initialHandleROI!
                        var newROI = initial // Start with initial ROI for each change
                        
                        switch position {
                        case .topLeft:
                            let maxDeltaX = initial.width - minBoxSize
                            let maxDeltaY = initial.height - minBoxSize
                            
                            // Calculate proposed deltas
                            var deltaX = min(value.translation.width, maxDeltaX)
                            var deltaY = min(value.translation.height, maxDeltaY)
                            
                            // Apply margin constraints
                            if initial.origin.x + deltaX < margin {
                                deltaX = margin - initial.origin.x
                            }
                            if initial.origin.y + deltaY < margin {
                                deltaY = margin - initial.origin.y
                            }
                            
                            newROI.origin.x = initial.origin.x + deltaX
                            newROI.origin.y = initial.origin.y + deltaY
                            newROI.size.width = initial.width - deltaX
                            newROI.size.height = initial.height - deltaY
                            
                        case .topRight:
                            let maxNegativeDeltaX = minBoxSize - initial.width
                            let maxDeltaY = initial.height - minBoxSize
                            
                            // Calculate proposed deltas
                            var deltaX = max(value.translation.width, maxNegativeDeltaX)
                            var deltaY = min(value.translation.height, maxDeltaY)
                            
                            // Apply margin constraints
                            if initial.origin.x + initial.width + deltaX > containerSize.width - margin {
                                deltaX = containerSize.width - margin - (initial.origin.x + initial.width)
                            }
                            if initial.origin.y + deltaY < margin {
                                deltaY = margin - initial.origin.y
                            }
                            
                            newROI.origin.y = initial.origin.y + deltaY
                            newROI.size.width = initial.width + deltaX
                            newROI.size.height = initial.height - deltaY
                            
                        case .bottomLeft:
                            let maxDeltaX = initial.width - minBoxSize
                            let maxNegativeDeltaY = minBoxSize - initial.height
                            
                            // Calculate proposed deltas
                            var deltaX = min(value.translation.width, maxDeltaX)
                            var deltaY = max(value.translation.height, maxNegativeDeltaY)
                            
                            // Apply margin constraints
                            if initial.origin.x + deltaX < margin {
                                deltaX = margin - initial.origin.x
                            }
                            if initial.origin.y + initial.height + deltaY > containerSize.height - margin {
                                deltaY = containerSize.height - margin - (initial.origin.y + initial.height)
                            }
                            
                            newROI.origin.x = initial.origin.x + deltaX
                            newROI.size.width = initial.width - deltaX
                            newROI.size.height = initial.height + deltaY
                            
                        case .bottomRight:
                            let maxNegativeDeltaX = minBoxSize - initial.width
                            let maxNegativeDeltaY = minBoxSize - initial.height
                            
                            // Calculate proposed deltas
                            var deltaX = max(value.translation.width, maxNegativeDeltaX)
                            var deltaY = max(value.translation.height, maxNegativeDeltaY)
                            
                            // Apply margin constraints
                            if initial.origin.x + initial.width + deltaX > containerSize.width - margin {
                                deltaX = containerSize.width - margin - (initial.origin.x + initial.width)
                            }
                            if initial.origin.y + initial.height + deltaY > containerSize.height - margin {
                                deltaY = containerSize.height - margin - (initial.origin.y + initial.height)
                            }
                            
                            newROI.size.width = initial.width + deltaX
                            newROI.size.height = initial.height + deltaY
                        }
                        
                        // Apply changes to the binding
                        roi = newROI
                    }
                    .onEnded { _ in
                        // Final cleanup to ensure constraints are met
                        roi = clampROI(roi)
                        initialHandleROI = nil
                    }
            )
            .accessibilityLabel("\(position.rawValue) resize handle")
            .accessibilityHint("Drag to resize the detection box")
    }
    
    /// Defines larger tap targets around box edges and corners
    private struct CombinedContentShape: Shape {
        let roi: CGRect
        let containerSize: CGSize
        let boxDragOffset: CGSize
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let adjustedROI = roi.offsetBy(dx: boxDragOffset.width, dy: boxDragOffset.height)
            
            
            let positions = [
                
                CGPoint(x: adjustedROI.minX, y: adjustedROI.minY),
                CGPoint(x: adjustedROI.maxX, y: adjustedROI.minY),
                CGPoint(x: adjustedROI.minX, y: adjustedROI.maxY),
                CGPoint(x: adjustedROI.maxX, y: adjustedROI.maxY),
                
                CGPoint(x: adjustedROI.midX, y: adjustedROI.minY),
                CGPoint(x: adjustedROI.midX, y: adjustedROI.maxY),
                CGPoint(x: adjustedROI.minX, y: adjustedROI.midY),
                CGPoint(x: adjustedROI.maxX, y: adjustedROI.midY)
            ]
            
            for position in positions {
                path.addEllipse(in: CGRect(
                    x: position.x - 15,
                    y: position.y - 15,
                    width: 30,
                    height: 30
                ))
            }
            
            let edgeThickness: CGFloat = 20

            path.addRect(CGRect(
                x: adjustedROI.minX,
                y: adjustedROI.minY - edgeThickness/2,
                width: adjustedROI.width,
                height: edgeThickness
            ))

            path.addRect(CGRect(
                x: adjustedROI.minX,
                y: adjustedROI.maxY - edgeThickness/2,
                width: adjustedROI.width,
                height: edgeThickness
            ))
            
            path.addRect(CGRect(
                x: adjustedROI.minX - edgeThickness/2,
                y: adjustedROI.minY,
                width: edgeThickness,
                height: adjustedROI.height
            ))
            
            path.addRect(CGRect(
                x: adjustedROI.maxX - edgeThickness/2,
                y: adjustedROI.minY,
                width: edgeThickness,
                height: adjustedROI.height
            ))
            
            return path
        }
    }
    
    /// Gets screen position for corner handles based on current box size
    private func handlePosition(for position: HandlePosition) -> CGPoint {
        switch position {
        case .topLeft: return CGPoint(x: roi.minX, y: roi.minY)
        case .topRight: return CGPoint(x: roi.maxX, y: roi.minY)
        case .bottomLeft: return CGPoint(x: roi.minX, y: roi.maxY)
        case .bottomRight: return CGPoint(x: roi.maxX, y: roi.maxY)
        }
    }
    
    /// Ensures box stays within screen bounds and maintains minimum size
    private func clampROI(_ rect: CGRect) -> CGRect {
        var newRect = rect
        
        // Ensure minimum width and height
        newRect.size.width = max(newRect.size.width, minBoxSize)
        newRect.size.height = max(newRect.size.height, minBoxSize)
        
        // Ensure box is within margins (left and top)
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        // Ensure box is within margins (right and bottom)
        if newRect.maxX > containerSize.width - margin {
            newRect.origin.x = containerSize.width - margin - newRect.size.width
        }
        
        if newRect.maxY > containerSize.height - margin {
            newRect.origin.y = containerSize.height - margin - newRect.size.height
        }
        
        // Final check for edge cases
        if newRect.origin.x < margin {
            newRect.origin.x = margin
        }
        
        if newRect.origin.y < margin {
            newRect.origin.y = margin
        }
        
        return newRect
    }
}

struct AdjustableBoundingBox_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            AdjustableBoundingBox(
                roi: .constant(CGRect(x: 100, y: 100, width: 200, height: 200)),
                containerSize: CGSize(width: 400, height: 800)
            )
        }
    }
}

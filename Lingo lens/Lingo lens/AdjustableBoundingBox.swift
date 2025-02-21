//
//  AdjustableBoundingBox.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI

struct AdjustableBoundingBox: View {
    @Binding var roi: CGRect
    
    // Pass in the size of the container in which you're drawing the bounding box
    var containerSize: CGSize
    
    // State for dragging the entire box.
    @State private var initialBoxROI: CGRect? = nil
    @State private var boxDragOffset: CGSize = .zero
    
    // State for resizing via handles.
    @State private var initialHandleROI: CGRect? = nil
    
    // Define the margin (8 points from each edge)
    private let margin: CGFloat = 8

    var body: some View {
        ZStack {
            // Draggable main rectangle...
            Rectangle()
                .stroke(Color.yellow, lineWidth: 3)
                .frame(width: roi.width, height: roi.height)
                // Apply boxDragOffset for the rectangle:
                .position(
                    x: roi.midX + boxDragOffset.width,
                    y: roi.midY + boxDragOffset.height
                )
            // In AdjustableBoundingBox.swift, inside the .gesture modifier for the main rectangle:
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if initialBoxROI == nil {
                                // Remember the ROI before drag
                                initialBoxROI = roi
                            }
                            var translation = value.translation
                            if let initial = initialBoxROI {
                                // Clamp right drag
                                if translation.width > 0 {
                                    let containerWidth = containerSize.width
                                    let maxRightTranslation = containerWidth - margin - (initial.origin.x + initial.width)
                                    translation.width = min(translation.width, maxRightTranslation)
                                }
                                // Clamp left drag
                                if translation.width < 0 {
                                    let maxLeftTranslation = margin - initial.origin.x  // negative value
                                    translation.width = max(translation.width, maxLeftTranslation)
                                }
                                // Clamp upward drag (translation.height < 0 means moving up)
                                if translation.height < 0 {
                                    let maxUpTranslation = margin - initial.origin.y  // negative value
                                    translation.height = max(translation.height, maxUpTranslation)
                                }
                                // Clamp downward drag
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
                                // Clamp right drag on drag end
                                if translation.width > 0 {
                                    let containerWidth = containerSize.width
                                    let maxRightTranslation = containerWidth - margin - (initial.origin.x + initial.width)
                                    translation.width = min(translation.width, maxRightTranslation)
                                }
                                // Clamp left drag on drag end
                                if translation.width < 0 {
                                    let maxLeftTranslation = margin - initial.origin.x
                                    translation.width = max(translation.width, maxLeftTranslation)
                                }
                                // Clamp upward drag on drag end
                                if translation.height < 0 {
                                    let maxUpTranslation = margin - initial.origin.y
                                    translation.height = max(translation.height, maxUpTranslation)
                                }
                                // Clamp downward drag on drag end
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
                )

            // Corner handles...
            handleView(for: .topLeft)
            handleView(for: .topRight)
            handleView(for: .bottomLeft)
            handleView(for: .bottomRight)
        }
        .contentShape(Rectangle())
    }
    
    enum HandlePosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    @ViewBuilder
    private func handleView(for position: HandlePosition) -> some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 30, height: 30)
            // Apply the SAME boxDragOffset to keep handles in sync with rectangle.
            .position(
                x: handlePosition(for: position).x + boxDragOffset.width,
                y: handlePosition(for: position).y + boxDragOffset.height
            )
            .gesture(
                DragGesture()
                // In AdjustableBoundingBox.swift, update the onChanged block inside handleView:
                    .onChanged { value in
                        if initialHandleROI == nil {
                            initialHandleROI = roi
                        }
                        let initial = initialHandleROI!
                        var newROI = roi
                        
                        switch position {
                        case .topLeft:
                            let deltaX = value.translation.width
                            let deltaY = value.translation.height
                            // For topLeft, dragging right (positive deltaX) reduces width.
                            // Clamp only if deltaX > (initial.width - 100)
                            let effectiveDeltaX: CGFloat = deltaX > 0 ? min(deltaX, initial.width - 100) : deltaX
                            // Similarly for vertical: positive deltaY reduces height.
                            let effectiveDeltaY: CGFloat = deltaY > 0 ? min(deltaY, initial.height - 100) : deltaY
                            
                            newROI.origin.x = initial.origin.x + effectiveDeltaX
                            newROI.origin.y = initial.origin.y + effectiveDeltaY
                            newROI.size.width = initial.width - effectiveDeltaX
                            newROI.size.height = initial.height - effectiveDeltaY
                            
                        case .topRight:
                            let deltaX = value.translation.width
                            let deltaY = value.translation.height
                            // For topRight, horizontal: new width = initial.width + deltaX.
                            // If deltaX is negative (reducing width), clamp so that width doesn't go below 100.
                            let effectiveDeltaX: CGFloat = deltaX < 0 ? max(deltaX, 100 - initial.width) : deltaX
                            // Vertical: new height = initial.height - deltaY.
                            let effectiveDeltaY: CGFloat = deltaY > 0 ? min(deltaY, initial.height - 100) : deltaY
                            
                            // x stays same.
                            newROI.origin.y = initial.origin.y + effectiveDeltaY
                            newROI.size.width = initial.width + effectiveDeltaX
                            newROI.size.height = initial.height - effectiveDeltaY
                            
                        case .bottomLeft:
                            let deltaX = value.translation.width
                            let deltaY = value.translation.height
                            // For bottomLeft, horizontal: new width = initial.width - deltaX.
                            let effectiveDeltaX: CGFloat = deltaX > 0 ? min(deltaX, initial.width - 100) : deltaX
                            // Vertical: new height = initial.height + deltaY.
                            let effectiveDeltaY: CGFloat = deltaY < 0 ? max(deltaY, 100 - initial.height) : deltaY
                            
                            newROI.origin.x = initial.origin.x + effectiveDeltaX
                            newROI.size.width = initial.width - effectiveDeltaX
                            // y remains unchanged.
                            newROI.size.height = initial.height + effectiveDeltaY
                            
                        case .bottomRight:
                            let deltaX = value.translation.width
                            let deltaY = value.translation.height
                            // For bottomRight, new width = initial.width + deltaX.
                            let effectiveDeltaX: CGFloat = deltaX < 0 ? max(deltaX, 100 - initial.width) : deltaX
                            // New height = initial.height + deltaY.
                            let effectiveDeltaY: CGFloat = deltaY < 0 ? max(deltaY, 100 - initial.height) : deltaY
                            
                            // For bottomRight, origin remains the same.
                            newROI.size.width = initial.width + effectiveDeltaX
                            newROI.size.height = initial.height + effectiveDeltaY
                        }
                        
                        roi = newROI
                    }

                    .onEnded { _ in
                        let newROI = clampROI(roi)
                        roi = newROI
                        initialHandleROI = nil
                    }
            )
    }
    
    // Computes the handle's current position based on the ROI (top-left origin).
    private func handlePosition(for position: HandlePosition) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: roi.minX, y: roi.minY)
        case .topRight:
            return CGPoint(x: roi.maxX, y: roi.minY)
        case .bottomLeft:
            return CGPoint(x: roi.minX, y: roi.maxY)
        case .bottomRight:
            return CGPoint(x: roi.maxX, y: roi.maxY)
        }
    }
    
    // Clamps the ROI so that its edges remain at least 'margin' points from the container.
    private func clampROI(_ rect: CGRect) -> CGRect {
        let containerWidth = containerSize.width
        let containerHeight = containerSize.height
        var newRect = rect
        
        // Ensure origin is not too far left/top.
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        // Ensure the right/bottom edges don't cross container edges.
        if newRect.maxX > containerWidth - margin {
            newRect.size.width = containerWidth - margin - newRect.origin.x
        }
        if newRect.maxY > containerHeight - margin {
            newRect.size.height = containerHeight - margin - newRect.origin.y
        }
        
        // Enforce minimum size of 100 points.
        newRect.size.width = max(newRect.size.width, 100)
        newRect.size.height = max(newRect.size.height, 100)
        
        return newRect
    }
}

struct AdjustableBoundingBox_Previews: PreviewProvider {
    static var previews: some View {
        AdjustableBoundingBox(roi: .constant(CGRect(x: 100, y: 100, width: 200, height: 200)), containerSize: CGSize(width: 400, height: 800))
    }
}

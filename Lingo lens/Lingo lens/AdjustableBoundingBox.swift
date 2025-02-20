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
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if initialBoxROI == nil {
                                // Remember the ROI before drag
                                initialBoxROI = roi
                            }
                            // Live update offset as we drag
                            boxDragOffset = value.translation
                        }
                        .onEnded { value in
                            // When drag ends, permanently update ROI
                            if let initial = initialBoxROI {
                                var newROI = CGRect(
                                    x: initial.origin.x + value.translation.width,
                                    y: initial.origin.y + value.translation.height,
                                    width: initial.width,
                                    height: initial.height
                                )
                                newROI = clampROI(newROI)
                                roi = newROI
                            }
                            initialBoxROI = nil
                            // Reset offset
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
                    .onChanged { value in
                        if initialHandleROI == nil {
                            initialHandleROI = roi
                        }
                        let initial = initialHandleROI!
                        var newROI = roi
                        
                        switch position {
                        case .topLeft:
                            newROI.origin.x = initial.origin.x + value.translation.width
                            newROI.origin.y = initial.origin.y + value.translation.height
                            newROI.size.width = initial.width - value.translation.width
                            newROI.size.height = initial.height - value.translation.height
                            
                        case .topRight:
                            newROI.origin.y = initial.origin.y + value.translation.height
                            newROI.size.width = initial.width + value.translation.width
                            newROI.size.height = initial.height - value.translation.height
                            
                        case .bottomLeft:
                            newROI.origin.x = initial.origin.x + value.translation.width
                            newROI.size.width = initial.width - value.translation.width
                            newROI.size.height = initial.height + value.translation.height
                            
                        case .bottomRight:
                            newROI.size.width = initial.width + value.translation.width
                            newROI.size.height = initial.height + value.translation.height
                        }
                        
                        // Enforce a minimum size (50 points).
                        if newROI.size.width >= 50, newROI.size.height >= 50 {
                            roi = newROI
                        }
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
    
    // Clamps the ROI so that its edges remain at least 'margin' points from the *container*.
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
        
        return newRect
    }
}

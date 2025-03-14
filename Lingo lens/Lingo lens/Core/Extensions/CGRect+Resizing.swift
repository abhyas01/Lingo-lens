//
//  CGRect+Resizing.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

/// Extension to adjust bounding box rectangles when screen size changes
/// or when device orientation shifts
extension CGRect {
    
    /// Makes sure the box stays properly sized and positioned when screen dimensions change
    func resizedAndClamped(from oldSize: CGSize, to newSize: CGSize, margin: CGFloat = 16) -> CGRect {
        guard oldSize != .zero, newSize != .zero else { return self }
        
        // Calculate scale factors based on size change
        let widthScale = newSize.width / oldSize.width
        let heightScale = newSize.height / oldSize.height
        
        // Calculate scale factors based on size change
        var newRect = CGRect(
            x: self.origin.x * widthScale,
            y: self.origin.y * heightScale,
            width: self.width * widthScale,
            height: self.height * heightScale
        )
        
        // Set minimum box sizes for usability
        let minWidth: CGFloat = 100
        let minHeight: CGFloat = 100
        
        // Calculate maximum allowed dimensions to stay within screen
        let maxWidth = newSize.width - (2 * margin)
        let maxHeight = newSize.height - (2 * margin)
        
        // Enforce size constraints
        newRect.size.width = max(minWidth, min(newRect.size.width, maxWidth))
        newRect.size.height = max(minHeight, min(newRect.size.height, maxHeight))
        
        // Enforce position constraints (top-left)
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        // Enforce position constraints (bottom-right)
        if newRect.maxX > newSize.width - margin {
            newRect.origin.x = newSize.width - margin - newRect.size.width
        }
        
        if newRect.maxY > newSize.height - margin {
            newRect.origin.y = newSize.height - margin - newRect.size.height
        }
        
        // Final position check to avoid edge cases
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        return newRect
    }
}

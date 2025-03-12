//
//  CGRect+Resizing.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

/// CGRect with resizing capabilities that maintain constraints when adjusting bounding boxes
extension CGRect {
    func resizedAndClamped(from oldSize: CGSize, to newSize: CGSize, margin: CGFloat = 16) -> CGRect {
        guard oldSize != .zero, newSize != .zero else { return self }
        
        let widthScale = newSize.width / oldSize.width
        let heightScale = newSize.height / oldSize.height
        
        var newRect = CGRect(
            x: self.origin.x * widthScale,
            y: self.origin.y * heightScale,
            width: self.width * widthScale,
            height: self.height * heightScale
        )
        
        let minWidth: CGFloat = 100
        let minHeight: CGFloat = 100
        
        let maxWidth = newSize.width - (2 * margin)
        let maxHeight = newSize.height - (2 * margin)
        
        newRect.size.width = max(minWidth, min(newRect.size.width, maxWidth))
        newRect.size.height = max(minHeight, min(newRect.size.height, maxHeight))
        
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        if newRect.maxX > newSize.width - margin {
            newRect.origin.x = newSize.width - margin - newRect.size.width
        }
        
        if newRect.maxY > newSize.height - margin {
            newRect.origin.y = newSize.height - margin - newRect.size.height
        }
        
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        return newRect
    }
}

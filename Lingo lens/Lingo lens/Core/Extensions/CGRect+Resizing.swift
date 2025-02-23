//
//  CGRect+Resizing.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import SwiftUI

extension CGRect {
    
    func resizedAndClamped(from oldSize: CGSize, to newSize: CGSize, margin: CGFloat = 8) -> CGRect {
        guard oldSize != .zero, newSize != .zero else { return self }
        
        let widthScale = newSize.width / oldSize.width
        let heightScale = newSize.height / oldSize.height
        
        var newRect = CGRect(
            x: self.origin.x * widthScale,
            y: self.origin.y * heightScale,
            width: self.width * widthScale,
            height: self.height * heightScale
        )
        
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        newRect.size.width = min(newRect.size.width, newSize.width - 2 * margin)
        newRect.size.height = min(newRect.size.height, newSize.height - 2 * margin)
        
        let minWidth: CGFloat = 100
        let minHeight: CGFloat = 100
        newRect.size.width = max(newRect.size.width, minWidth)
        newRect.size.height = max(newRect.size.height, minHeight)
        
        if newRect.maxX > newSize.width - margin {
            newRect.origin.x = newSize.width - margin - newRect.size.width
        }
        if newRect.maxY > newSize.height - margin {
            newRect.origin.y = newSize.height - margin - newRect.size.height
        }
        
        return newRect
    }
}

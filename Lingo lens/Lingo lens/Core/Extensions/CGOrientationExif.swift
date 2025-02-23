//
//  CGOrientationExif.swift.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//

import CoreImage

extension CGImagePropertyOrientation {
    
    var numericValue: Int32 {
        switch self {
        case .up:            return 1
        case .upMirrored:    return 2
        case .down:          return 3
        case .downMirrored:  return 4
        case .leftMirrored:  return 5
        case .right:         return 6
        case .rightMirrored: return 7
        case .left:          return 8
        @unknown default:    return 1
        }
    }
}

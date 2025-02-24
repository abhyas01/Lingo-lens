//
//  DeviceOrientation.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import UIKit

/// Maps device orientation to EXIF orientation for correct image handling in AR and vision processing
extension UIDeviceOrientation {
    
    var exifOrientation: CGImagePropertyOrientation {
        switch self {
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        case .portrait:
            return .right
        default:
            return .right
        }
    }
}

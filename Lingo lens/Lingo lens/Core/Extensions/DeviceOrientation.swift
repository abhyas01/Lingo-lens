//
//  DeviceOrientation.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import UIKit

/// Converts device orientation to the image orientation format needed by the AR camera
extension UIDeviceOrientation {
    
    // Maps physical device orientation to the correct image orientation for AR processing
    // This helps make sure text recognition works in any orientation
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

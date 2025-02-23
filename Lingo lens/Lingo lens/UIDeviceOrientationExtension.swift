//
//  UIDeviceOrientationExtension.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import UIKit

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

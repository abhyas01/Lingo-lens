//
//  CameraPermissionManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//


import SwiftUI
import AVFoundation

/// Manages camera permission state and user interactions for AR functionality
/// Handles permission checks, requests, and settings navigation
class CameraPermissionManager: ObservableObject {
    
    /// Shows alert when camera access is denied/restricted or needs to be requested
    @Published var showPermissionAlert = false
    
    // MARK: - Permission Handling

    /// Checks current camera authorization status and updates UI accordingly
    /// Also sets up periodic rechecks if permission isn't granted
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showPermissionAlert = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
        
        // Keep checking periodically if we don't have permission yet
        if !showPermissionAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkPermission()
            }
        }
    }
    
    // MARK: - Settings Navigation

    /// Takes user to app's settings page in iOS Settings app
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

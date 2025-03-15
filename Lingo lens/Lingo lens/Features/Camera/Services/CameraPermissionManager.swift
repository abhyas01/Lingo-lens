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
    
    // Shows alert when camera access is denied/restricted or needs to be requested
    @Published var showPermissionAlert = true
    
    // Properties for log throttling
    private var lastLogTime: Date = Date.distantPast
    private let logThrottleInterval: TimeInterval = 5
    
    // Add a property to track if checking is active
    private var isCheckingActive = false

    // MARK: - Permission Handling

    /// Checks current camera authorization status and updates UI accordingly
    /// Also sets up periodic rechecks if permission isn't granted
    func checkPermission() {
        guard isCheckingActive else { return }
        
        // Check current permission status using AVFoundation
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        
        case .authorized:
            
            // Throttle logging - only log if 5 seconds have passed
            let now = Date()
            if now.timeIntervalSince(lastLogTime) >= logThrottleInterval {
                print("✅ Camera access already granted")
                lastLogTime = now
            }

            // Camera access already granted, clear any alert
            showPermissionAlert = false
            
        case .notDetermined:
            
            print("❓ Camera permission not determined yet - requesting access")
            
            // First time asking for camera access - show system permission dialog
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        print("❌ User denied camera permission")

                        // User denied permission in system dialog
                        self.showPermissionAlert = true
                    } else {
                        print("✅ User granted camera permission")
                        
                        // User allowed permission in system dialog
                        self.showPermissionAlert = false
                    }
                }
            }
            
        case .denied, .restricted:
            
            print("❌ Camera access previously denied or ⚠️ Camera access restricted")

            // Camera access previously denied or restricted by parental controls
            showPermissionAlert = true
            
        @unknown default:
            
            print("⚠️ Unknown camera permission status")
            
            // Handle any future cases by showing the alert
            showPermissionAlert = true
        }
        
        // Keep checking periodically if we don't have permission yet
        // This helps detect if user grants permission in Settings outside the app
        if !showPermissionAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkPermission()
            }
        }
    }
    
    // Start checking permissions
    func startChecking() {
        isCheckingActive = true
        checkPermission()
    }
    
    // Stop checking permissions
    func stopChecking() {
        isCheckingActive = false
    }
    
    // MARK: - Settings Navigation

    /// Takes user to app's settings page in iOS Settings app
    /// User can enable camera permission there if previously denied
    func openAppSettings() {
        print("⚙️ Opening app settings for camera permission")

        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            print("❌ Could not create settings URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            print("✅ Opened settings app")
            UIApplication.shared.open(settingsUrl)
        } else {
            print("❌ Could not open settings app")
        }
    }
}

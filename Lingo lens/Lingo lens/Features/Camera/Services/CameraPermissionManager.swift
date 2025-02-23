//
//  CameraPermissionManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/22/25.
//


import SwiftUI
import AVFoundation

class CameraPermissionManager: ObservableObject {
    @Published var showPermissionAlert = false
    
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
        
        if !showPermissionAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkPermission()
            }
        }
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
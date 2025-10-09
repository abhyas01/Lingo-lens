//
//  SplashScreen.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/22/25.
//

import SwiftUI

struct SplashScreen: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Launch Screen", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed for a static launch screen
    }
}

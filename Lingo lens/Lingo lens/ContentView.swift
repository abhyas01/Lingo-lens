//
//  ContentView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 2/18/25.
//

import SwiftUI
import ARKit

struct ContentView: View {
    @StateObject private var arViewModel = ARViewModel()
    
    var body: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Use GeometryReader to initialize and overlay the adjustable ROI.
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        if arViewModel.adjustableROI == .zero {
                            let boxSize: CGFloat = 200
                            arViewModel.adjustableROI = CGRect(
                                x: (geo.size.width - boxSize) / 2,
                                y: (geo.size.height - boxSize) / 2,
                                width: boxSize,
                                height: boxSize
                            )
                        }
                    }

                // Pass in containerSize: geo.size
                AdjustableBoundingBox(
                    roi: $arViewModel.adjustableROI,
                    containerSize: geo.size
                )
            }
            
            // Top label: “Keep Moving…” or the detected object name.
            VStack {
                Text(arViewModel.detectedObjectName.isEmpty ? "Keep Moving…" : arViewModel.detectedObjectName)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Spacer()
            }
            .padding(.top, 50)
            
            // Plus button to add an annotation (placed at bottom-right).
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        arViewModel.addAnnotation()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

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
    @State private var previousSize: CGSize = .zero // Store the previous screen size

    var body: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)

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
                        previousSize = geo.size
                    }
                    // iOS 17+ onChange with zero-parameter closure
                    .onChange(of: geo.size) {
                        guard geo.size != previousSize else { return }
                        
                        // Recalculate ROI to maintain position in new orientation
                        arViewModel.adjustableROI = arViewModel.adjustableROI
                            .resizedAndClamped(from: previousSize, to: geo.size)
                        
                        previousSize = geo.size
                    }
                
                AdjustableBoundingBox(
                    roi: $arViewModel.adjustableROI,
                    containerSize: geo.size
                )
            }
            
            // Display detected object name with tinted background.
            VStack {
                // When nothing is detected, show "Cannot detect, keep moving" in light red;
                // when detected, show the detected name in light green.
                let labelText = arViewModel.detectedObjectName.isEmpty ? "Cannot detect, keep moving" : arViewModel.detectedObjectName
                let labelBackground = arViewModel.detectedObjectName.isEmpty ? Color.red.opacity(0.8) : Color.green.opacity(0.8)
                
                Text(labelText)
                    .padding(8)
                    .background(labelBackground)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Spacer()
            }
            .padding(.top, 50)
            
            // Plus button for adding annotation; disabled when nothing is detected.
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
                            .foregroundColor(arViewModel.detectedObjectName.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                            .padding()
                    }
                    .disabled(arViewModel.detectedObjectName.isEmpty)
                }
            }
        }
    }
}

extension CGRect {
    func resizedAndClamped(from oldSize: CGSize, to newSize: CGSize, margin: CGFloat = 8) -> CGRect {
        guard oldSize != .zero, newSize != .zero else { return self }
        
        // Calculate scaling factor for width and height.
        let widthScale = newSize.width / oldSize.width
        let heightScale = newSize.height / oldSize.height
        
        // Adjust the ROI dimensions to match the new screen size.
        var newRect = CGRect(
            x: self.origin.x * widthScale,
            y: self.origin.y * heightScale,
            width: self.width * widthScale,
            height: self.height * heightScale
        )
        
        // Clamp origin so it doesn't go past the margin.
        newRect.origin.x = max(margin, newRect.origin.x)
        newRect.origin.y = max(margin, newRect.origin.y)
        
        // Clamp the size so it doesn't exceed container bounds minus margins.
        newRect.size.width = min(newRect.size.width, newSize.width - 2 * margin)
        newRect.size.height = min(newRect.size.height, newSize.height - 2 * margin)
        
        // Enforce a minimum size of 100 points for both width and height.
        let minWidth: CGFloat = 100
        let minHeight: CGFloat = 100
        newRect.size.width = max(newRect.size.width, minWidth)
        newRect.size.height = max(newRect.size.height, minHeight)
        
        // Final clamp: ensure the ROI stays within container bounds.
        if newRect.maxX > newSize.width - margin {
            newRect.origin.x = newSize.width - margin - newRect.size.width
        }
        if newRect.maxY > newSize.height - margin {
            newRect.origin.y = newSize.height - margin - newRect.size.height
        }
        
        return newRect
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

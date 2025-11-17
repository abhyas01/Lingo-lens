//
//  ListeningIndicator.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import SwiftUI

/// Animated waveform indicator for listening state
struct ListeningIndicator: View {

    @Binding var audioLevel: Float
    @State private var animationPhase: CGFloat = 0

    private let barCount = 5
    private let barWidth: CGFloat = 4
    private let barSpacing: CGFloat = 4
    private let minHeight: CGFloat = 8
    private let maxHeight: CGFloat = 32

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(barColor(for: index))
                    .frame(width: barWidth, height: barHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1.0
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight = minHeight + (maxHeight - minHeight) * CGFloat(audioLevel)
        let variation = sin(animationPhase * .pi + Double(index) * 0.5) * 0.3 + 0.7
        return baseHeight * CGFloat(variation)
    }

    private func barColor(for index: Int) -> Color {
        let intensity = 0.6 + (Double(index) / Double(barCount)) * 0.4
        return Color.blue.opacity(intensity)
    }
}

#Preview {
    VStack(spacing: 30) {
        ListeningIndicator(audioLevel: .constant(0.3))
        ListeningIndicator(audioLevel: .constant(0.7))
        ListeningIndicator(audioLevel: .constant(1.0))
    }
    .padding()
}

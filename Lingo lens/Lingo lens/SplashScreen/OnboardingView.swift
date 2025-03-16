//
//  OnboardingView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/14/25.
//

import SwiftUI

/// Main onboarding view displayed when app is first launched
/// Presents a swipeable walkthrough of app features
struct OnboardingView: View {
    
    // Track device size details for responsive layout decisions
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Track which page is currently being shown
    @State private var currentPage = 0
    
    // Callback to dismiss onboarding when complete
    var onDismiss: () -> Void
    
    // Compute sizing based on device
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    // Detect landscape orientation for adaptive layout
    private var isCompactVertical: Bool {
        verticalSizeClass == .compact
    }
    
    // Content for each onboarding screen
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "camera.viewfinder",
            title: "Translate Your World",
            description: "Point your camera at objects around you, then add labels that translate to your chosen language."
        ),
        OnboardingPage(
            image: "hand.tap.fill",
            title: "Interactive Learning",
            description: "Tap labels to see translations, hear pronunciations, and save words."
        ),
        OnboardingPage(
            image: "bookmark.fill",
            title: "Build Your Vocabulary",
            description: "All saved translations are organized in your personal collection."
        ),
        OnboardingPage(
            image: "gear",
            title: "Select Language",
            description: "Select your language of choice from the settings."
        )
    ]
    
    var body: some View {
        VStack {
            
            // Header section with icon and title
            VStack {
                Image(systemName: "translate")
                    .font(.system(size: isCompactVertical ? 40 : 60))
                    .foregroundColor(.blue)
                    .padding(.bottom, isCompactVertical ? 0 : 8)
                
                Text("Lingo lens")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Hide tagline in landscape to save vertical space
                if !isCompactVertical {
                    Text("Learn languages naturally")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Text("Created by Abhyas Mall")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
            }
            .padding(.top, isIPad ? 50 : isCompactVertical ? 8 : 18)
            .padding(.bottom, 20)
            
            Spacer()
            
            // Page content with TabView for swiping between pages
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    if isCompactVertical {
                        
                        // Horizontal layout for landscape orientation
                        HStack {
                            
                            Spacer()
                            
                            // Feature icon with background - smaller in landscape
                            Image(systemName: pages[index].image)
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(Circle().fill(.blue).opacity(0.1))
                            
                            Spacer()
                            
                            // Description text with leading alignment for better readability in landscape
                            Text(pages[index].description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(2)
                            
                            Spacer()
                            
                            }
                            .padding(.horizontal)
                            .tag(index)
                            .padding()
                        
                        } else {
                        
                        // Description text with leading alignment for better readability in landscape
                        VStack {
                            
                            Spacer()
                            
                            // Feature icon with background
                            Image(systemName: pages[index].image)
                                .font(.system(size: isIPad ? 120 : 60))
                                .foregroundColor(.blue)
                                .padding(isIPad ? 30 : 15)
                                .background(Circle().fill(.blue).opacity(0.1))
                                .padding(.bottom)
                            
                            // Feature title and description
                            VStack {
                                Text(pages[index].title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                                
                                Text(pages[index].description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(2)
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        .tag(index)
                        .padding()
                        
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            Spacer()
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                }
            }
            .padding()
            
            // Start button
            Button(action: onDismiss) {
                Text("Start Learning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding()
            .padding(.bottom)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
}

/// Represents content for a single onboarding page
struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

#Preview {
    OnboardingView {
        print("Onboarding dismissed")
    }
}

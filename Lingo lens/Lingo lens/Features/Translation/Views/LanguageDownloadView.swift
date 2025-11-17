//
//  LanguageDownloadView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//


import SwiftUI
import Translation

/// Manages the UI for downloading translation language packages
/// Shows download progress, success, and failure states
struct LanguageDownloadView: View {
    
    // Language that needs to be downloaded
    let language: AvailableLanguage
    
    // Controls whether this sheet is visible
    @Binding var isPresented: Bool
    
    // Function to run when download completes successfully
    var onDownloadComplete: () -> Void
    
    // Access to the app's translation service
    @EnvironmentObject var translationService: TranslationService
    
    // Configuration needed for translation API
    @State private var configuration: TranslationSession.Configuration?
    
    // Track the various states of the download process
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var downloadFailed = false
    @State private var isVerifyingDownload = false
    @State private var isPerformingAction = false
    
    // For continuously checking if download completed in Settings app
    @State private var periodicCheckTimer: Timer?
    
    init(language: AvailableLanguage, isPresented: Binding<Bool>, onDownloadComplete: @escaping () -> Void) {
        self.language = language
        self._isPresented = isPresented
        self.onDownloadComplete = onDownloadComplete
        Logger.debug("📥 Language download view initialized for: \(language.localizedName()) (\(language.shortName()))")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Close button in the top-right corner
                HStack {
                    Spacer()
                    Button(action: {
                        Logger.debug("👆 Button pressed: Close language download view")
                        stopPeriodicCheck()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal)
                
                // Header section with icon and explanation
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Download Language")
                        .font(.title2.bold())
                    
                    Text("To use \(language.localizedName()) for translations, you need to download the language pack first.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                // Conditional display based on download state
                if downloadComplete {
                    
                    // Success state - download completed
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text("Download Complete")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Button(action: {
                            Logger.debug("👆 Button pressed: Continue after download")

                            isPerformingAction = true
                            stopPeriodicCheck()
                            
                            // Small delay to show the action is in progress
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                Logger.info(" Download complete, dismissing view and continuing")

                                isPresented = false
                                onDownloadComplete()
                            }
                        }) {
                            HStack {
                                Text("Continue")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                if isPerformingAction {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                        .padding(.leading, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isPerformingAction)
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.top, 20)
                } else if isVerifyingDownload {
                    
                    // Checking if download is complete state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Verifying download...")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                } else if downloadFailed {
                    
                    // Error state - download didn't complete
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                            .padding(.top, 20)
                        
                        Text("Download Not Completed")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Please download \(language.localizedName()) from the Settings app to continue.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Open Settings") {
                            openAppSettings()
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                } else if isDownloading {
                    
                    // In-progress state - download is happening
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 20)
                            
                        Text("Preparing language...")
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 20)
                        
                        // Help text for when the system download dialog doesn't appear
                        Text("If you did not get the option to download \(language.localizedName())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 15)
                        
                        Text("Download manually by going to:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 15)
                        
                        Text("Settings > Apps > Translate > Downloaded Languages > \(language.localizedName())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 15)
                            .padding(.bottom, 20)
                        
                        Button(action: {
                            openAppSettings()
                        }) {
                            Text("Go to settings")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue).opacity(0.2))
                        }
                    }
                } else {
                    
                    // Initial state - download not started yet
                    VStack(spacing: 16) {
                        Button(action: startDownload) {
                            Text("Download Now")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Text("or")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Open Settings to Download") {
                            Logger.debug("👆 Button pressed: Open settings for language download")
                            openAppSettings()
                        }
                        .font(.headline)
                        .foregroundStyle(.blue)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                }
                
                // Information for manual download
                if !downloadComplete && !isDownloading && !isVerifyingDownload {
                    VStack(spacing: 8) {
                        Text("To download manually:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Settings > Apps > Translate > Downloaded Languages > \(language.localizedName())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 15)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
            
            // Hidden view that performs the actual translation task
            .translationTask(configuration) { session in
                if isDownloading {
                    do {
                        Logger.debug(" Executing translation task to prepare language: \(language.shortName())")

                        // This triggers the iOS download dialog for the language
                        try await session.prepareTranslation()
                        Logger.info(" Initiated language download for: \(language.shortName())")
                        
                        await MainActor.run {
                            isDownloading = false
                            isVerifyingDownload = true
                            Logger.debug(" Starting verification after download initiation")

                            // Wait a moment before checking if download completed
                            Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                Logger.debug(" Performing verification check after delay")
                                verifyLanguageDownloaded()
                            }
                        }
                    } catch {
                        Logger.error(" Failed to prepare language download: \(error.localizedDescription)")

                        await MainActor.run {
                            isDownloading = false
                            isVerifyingDownload = false
                            downloadFailed = true
                            configuration = nil
                        }
                    }
                }
            }
            .onAppear {
                startPeriodicCheck()
            }
            .onDisappear {
                stopPeriodicCheck()
            }
        }
    }
    
    /// Checks if the language has been downloaded
    /// Updates UI based on download status
    private func verifyLanguageDownloaded() {
        Logger.debug(" Verifying if language \"\(language.shortName())\" is downloaded")

        Task {
            isVerifyingDownload = true
            let isDownloaded = await translationService.isLanguageDownloaded(language: language)
            
            await MainActor.run {
                isVerifyingDownload = false
                downloadComplete = isDownloaded
                downloadFailed = !isDownloaded

                if isDownloaded {
                    Logger.info(" Language \"\(language.shortName())\" is downloaded")

                    configuration = nil
                } else {
                    Logger.error(" Language \"\(language.shortName())\" is not downloaded")
                }
            }
        }
    }
    
    /// Initiates the language download process
    private func startDownload() {
        Logger.debug("👆 Button pressed: Start language download")
        Logger.debug("📥 Starting download for language: \"\(language.shortName())\"")

        isDownloading = true
        downloadFailed = false
        
        configuration = TranslationSession.Configuration(
            source: translationService.sourceLanguage,
            target: language.locale
        )
    }
    
    /// Opens iOS Settings app to manually download the language
    private func openAppSettings() {
        Logger.debug("⚙️ Opening app settings for language download")

        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            Logger.error(" Could not create settings URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            Logger.info(" Opened settings app")
        } else {
            Logger.error(" Could not open settings app")
        }
    }

// MARK: - Periodic Check Methods
    
    /// Starts a timer to periodically check if language was downloaded
    /// Useful when user downloads language through Settings app
    private func startPeriodicCheck() {
        stopPeriodicCheck()
        Logger.info(" Starting periodic check for language download status: \(language.shortName())")
        
        periodicCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in

            // Only check if we're not already showing success or checking
            if !downloadComplete && !isVerifyingDownload {
                checkLanguageDownloadStatus()
            }
        }
    }
    
    /// Stops the periodic check timer
    private func stopPeriodicCheck() {
        Logger.info(" Stopping periodic language download check")
        periodicCheckTimer?.invalidate()
        periodicCheckTimer = nil
    }
    
    /// Checks if language has been downloaded in the background
    private func checkLanguageDownloadStatus() {
        Task {
            let isDownloaded = await translationService.isLanguageDownloaded(language: language)
            
            if isDownloaded {
                Logger.info(" Periodic check detected successful download of language: \(language.shortName())")

                await MainActor.run {
                    downloadComplete = true
                    downloadFailed = false
                    configuration = nil
                }
            }
        }
    }
}

#Preview {
    let language = AvailableLanguage(locale: .init(languageCode: "fr", region: "FR"))
    
    return LanguageDownloadView(
        language: language,
        isPresented: .constant(true),
        onDownloadComplete: {}
    )
    .environmentObject(TranslationService())
    .environmentObject(AppearanceManager())
}

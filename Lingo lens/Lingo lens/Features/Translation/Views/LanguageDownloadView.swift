//
//  LanguageDownloadView.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/11/25.
//


import SwiftUI
import Translation

struct LanguageDownloadView: View {
    let language: AvailableLanguage
    @Binding var isPresented: Bool
    var onDownloadComplete: () -> Void
    
    @EnvironmentObject var translationService: TranslationService
    @State private var configuration: TranslationSession.Configuration?
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var downloadFailed = false
    @State private var isVerifyingDownload = false
    
    init(language: AvailableLanguage, isPresented: Binding<Bool>, onDownloadComplete: @escaping () -> Void) {
        self.language = language
        self._isPresented = isPresented
        self.onDownloadComplete = onDownloadComplete
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal)
                
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
                
                if downloadComplete {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text("Download Complete")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Button("Continue") {
                            isPresented = false
                            onDownloadComplete()
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.top, 20)
                } else if isVerifyingDownload {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Verifying download...")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                } else if downloadFailed {
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
                            isPresented = false
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Button("Check Again") {
                            verifyLanguageDownloaded()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                } else if isDownloading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 20)
                            
                        Text("Preparing language...")
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 20)
                        
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
                            isPresented = false
                        }) {
                            Text("Go to settings")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue).opacity(0.2))
                        }
                    }
                } else {
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
                            openAppSettings()
                            isPresented = false
                        }
                        .font(.headline)
                        .foregroundStyle(.blue)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                }
                
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
            .translationTask(configuration) { session in
                if isDownloading {
                    do {
                        try await session.prepareTranslation()
                        await MainActor.run {
                            isDownloading = false
                            isVerifyingDownload = true
                        
                            Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                
                                verifyLanguageDownloaded()
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isDownloading = false
                            isVerifyingDownload = false
                            downloadFailed = true
                            configuration = nil
                        }
                    }
                }
            }
        }
    }
    
    private func verifyLanguageDownloaded() {
        Task {
            isVerifyingDownload = true
            let isDownloaded = await translationService.isLanguageDownloaded(language: language)
            
            await MainActor.run {
                isVerifyingDownload = false
                downloadComplete = isDownloaded
                downloadFailed = !isDownloaded

                if isDownloaded {
                    configuration = nil
                }
            }
        }
    }
    
    private func startDownload() {
        isDownloading = true
        downloadFailed = false
        
        configuration = TranslationSession.Configuration(
            source: translationService.sourceLanguage,
            target: language.locale
        )
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    let language = AvailableLanguage(locale: Locale.Language(languageCode: "fr", region: "FR"))
    
    return LanguageDownloadView(
        language: language,
        isPresented: .constant(true),
        onDownloadComplete: {}
    )
    .environmentObject(TranslationService())
}

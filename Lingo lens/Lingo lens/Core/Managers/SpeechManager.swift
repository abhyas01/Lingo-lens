//
//  SpeechManager.swift
//  Lingo lens
//
//  Created by Abhyas Mall on 3/13/25.
//

import AVFoundation
import SwiftUI

/// Singleton manager for handling all speech synthesis throughout the app
/// Prevents lag by maintaining a single instance of AVSpeechSynthesizer
class SpeechManager: NSObject, ObservableObject {
    
    // Shared instance for whole app to use
    static let shared = SpeechManager()
    
    // MARK: - Published Properties

    // True when preparing to speak but not yet speaking
    @Published var isLoading = false
    
    // True while actively speaking text
    @Published var isSpeaking = false
    
    // MARK: - Private Properties

    // The actual speech engine from Apple's framework
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // Tracks if audio session is ready for playback
    private var isAudioSessionPrepared = false
    
    // Setup the speech delegate when created
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        setupAudioSessionNotifications()
    }

    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Session Management

    /// Sets up audio session interruption notifications
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    /// Handles audio session interruptions (phone calls, alarms, etc.)
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            Logger.info("Audio session interrupted - stopping speech")
            stopSpeaking()

        case .ended:
            Logger.info("Audio session interruption ended")
            // Reset audio session prepared flag
            isAudioSessionPrepared = false

            // Check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    Logger.debug("Resuming audio session after interruption")
                    prepareAudioSession()
                }
            }

        @unknown default:
            Logger.warning("Unknown audio session interruption type")
        }
    }

    /// Handles audio route changes (headphones plugged/unplugged, etc.)
    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            Logger.info("Audio route changed - device disconnected")
            stopSpeaking()

        default:
            Logger.debug("Audio route changed: \(reason.rawValue)")
        }
    }

    /// Sets up the audio session for speech playback
    /// Configures how speech interacts with other audio on the device
    func prepareAudioSession() {
        // Check if session is already active and properly configured
        let session = AVAudioSession.sharedInstance()
        if isAudioSessionPrepared && session.category == .playback {
            Logger.debug("Audio session already prepared")
            return
        }

        do {
            Logger.info("Preparing audio session for speech playback")

            // Configure the audio session for speech playback
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try session.setActive(true)
            isAudioSessionPrepared = true
            Logger.info("Audio session prepared successfully")
        } catch {
            Logger.error("Failed to configure audio session: \(error.localizedDescription)")
            isAudioSessionPrepared = false
        }
    }
    
    /// Speaks the provided text in the specified language
    /// - Parameters:
    ///   - text: The text to speak
    ///   - languageCode: The language code (like "en-US" or "es-ES")
    func speak(text: String, languageCode: String) {
        Logger.debug("Speaking text: \"\(text)\" in language: \(languageCode)")

        // Make sure audio session is ready
        prepareAudioSession()

        isLoading = true

        // Stop any ongoing speech
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)

        // Get the base language code (like "en" from "en-US")
        let baseCode = languageCode.split(separator: "-").first ?? Substring("en")
        Logger.debug("Using base language code: \(baseCode)")

        // Try different approaches to find a voice for the language
        if let voice = AVSpeechSynthesisVoice(language: String(baseCode)) {
            Logger.debug("Found voice for base language code: \(baseCode)")
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            Logger.debug("Found voice for full language code: \(languageCode)")
            utterance.voice = voice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(language: "en-US") {
            Logger.warning("No voice found for \(languageCode), using English fallback")
            utterance.voice = fallbackVoice
        } else {
            Logger.error("No voices available at all")
            isLoading = false
            SpeechErrorManager.shared.showError(
                message: "Unable to play audio: No voices available",
                retryAction: nil
            )
            return
        }

        // Adjust speech properties using constants
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * SpeechConstants.defaultSpeechRateMultiplier
        utterance.pitchMultiplier = SpeechConstants.defaultPitchMultiplier
        utterance.volume = SpeechConstants.defaultVolume

        speechSynthesizer.speak(utterance)
    }

    /// Overload to accept Locale.Language
    func speak(text: String, language: Locale.Language) {
        speak(text: text, languageCode: language.minimalIdentifier)
    }
    
    /// Stops any ongoing speech immediately
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .word)
        isLoading = false
        isSpeaking = false
    }
    
    /// Cleans up the audio session when not needed anymore
    /// Helps prevent audio conflicts with other apps
    func deactivateAudioSession() {
        stopSpeaking()

        guard isAudioSessionPrepared else {
            Logger.debug("Audio session not active - nothing to deactivate")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isAudioSessionPrepared = false
            Logger.info("Audio session deactivated")
        } catch {
            Logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechManager: AVSpeechSynthesizerDelegate {

    // Called when speech starts
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Logger.debug("Speech started for text: \"\(utterance.speechString)\"")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.isSpeaking = true
        }
    }

    // Called when speech finishes normally
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Logger.debug("Speech finished for text: \"\(utterance.speechString)\"")
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }

    // Called when speech is cancelled
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Logger.debug("Speech cancelled")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.isSpeaking = false
        }
    }

    // Called when speech is paused
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Logger.debug("Speech paused")
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }

    // Called when paused speech continues
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Logger.debug("Speech resumed")
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = true
        }
    }
}

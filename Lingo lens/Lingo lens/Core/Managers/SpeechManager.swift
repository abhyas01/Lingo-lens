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
    }
    
    // MARK: - Audio Session Management

    /// Sets up the audio session for speech playback
    /// Configures how speech interacts with other audio on the device
    func prepareAudioSession() {
        
        // Skip if already prepared
        guard !isAudioSessionPrepared else {
            print("🔊 Audio session already prepared - skipping")
            return
        }
        
        do {
            print("🔊 Preparing audio session for speech playback")

            // Configure the audio session for speech playback
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            isAudioSessionPrepared = true
            print("✅ Audio session prepared successfully")
        } catch {
            // On failure not informing the user
            // Because preparation of audio session is only to enhance performance
            // so that its smooth when user taps on a label to hear pronunciation
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    /// Speaks the provided text in the specified language
    /// - Parameters:
    ///   - text: The text to speak
    ///   - languageCode: The language code (like "en-US" or "es-ES")
    func speak(text: String, languageCode: String) {
        print("🗣️ Speaking text: \"\(text)\" in language: \(languageCode)")

        // Make sure audio session is ready
        prepareAudioSession()
        
        isLoading = true
        
        // Stop any ongoing speech
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Get the base language code (like "en" from "en-US")
        let baseCode = languageCode.split(separator: "-").first ?? Substring("en")
        print("🔍 Using base language code: \(baseCode)")
        
        // Try different approaches to find a voice for the language
        if let voice = AVSpeechSynthesisVoice(language: String(baseCode)) {
            print("✅ Found voice for base language code: \(baseCode)")
            utterance.voice = voice
        } else {
            if let voice = AVSpeechSynthesisVoice(language: languageCode) {
                print("✅ Found voice for full language code: \(languageCode)")
                utterance.voice = voice
            } else if let fallbackVoice = AVSpeechSynthesisVoice(language: "en-US") {
                
                print("⚠️ No voice found for \(languageCode), using English fallback")
                // Fall back to English if needed
                utterance.voice = fallbackVoice
            } else {
                print("❌ No voices available at all")
                isLoading = false
                SpeechErrorManager.shared.showError(
                    message: "Unable to play audio: No voices available",
                    retryAction: nil
                )
                return
            }
        }
        
        // Adjust speech properties
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
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
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isAudioSessionPrepared = false
            print("Audio session deactivated")
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechManager: AVSpeechSynthesizerDelegate {
    
    // Called when speech starts
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🔊 Speech started for text: \"\(utterance.speechString)\"")
        DispatchQueue.main.async {
            self.isLoading = false
            self.isSpeaking = true
        }
    }
    
    // Called when speech finishes normally
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ Speech finished for text: \"\(utterance.speechString)\"")
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // Called when speech is cancelled
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isSpeaking = false
        }
    }
    
    // Called when speech is paused
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // Called when paused speech continues
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
}

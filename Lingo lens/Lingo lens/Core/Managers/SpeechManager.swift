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
    static let shared = SpeechManager()
    
    @Published var isLoading = false
    @Published var isSpeaking = false
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var isAudioSessionPrepared = false
    
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    /// Explicitly prepare the audio session when needed
    func prepareAudioSession() {
        guard !isAudioSessionPrepared else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            isAudioSessionPrepared = true
            print("Audio session prepared successfully")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    func speak(text: String, languageCode: String) {
        prepareAudioSession()
        
        isLoading = true
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        
        let baseCode = languageCode.split(separator: "-").first ?? Substring("en")
        
        if let voice = AVSpeechSynthesisVoice(language: String(baseCode)) {
            utterance.voice = voice
        } else {
            if let voice = AVSpeechSynthesisVoice(language: languageCode) {
                utterance.voice = voice
            } else if let fallbackVoice = AVSpeechSynthesisVoice(language: "en-US") {
                utterance.voice = fallbackVoice
                print("Voice not available for \(languageCode), using English fallback")
            } else {
                isLoading = false
                SpeechErrorManager.shared.showError(
                    message: "Unable to play audio: No voices available",
                    retryAction: nil
                )
                return
            }
        }
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isLoading = false
        isSpeaking = false
    }
    
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
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
}

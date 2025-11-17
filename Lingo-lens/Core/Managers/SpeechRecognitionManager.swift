//
//  SpeechRecognitionManager.swift
//  Lingo-lens
//
//  Created by Claude on 11/17/25.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Manages speech recognition for voice input and conversation transcription
class SpeechRecognitionManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isRecording: Bool = false
    @Published var transcript: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    @Published var isAuthorized: Bool = false

    // MARK: - Private Properties

    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?

    // Voice Activity Detection
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5
    private var lastAudioTime: Date = Date()
    private var onFinalTranscript: ((String) -> Void)?

    // MARK: - Initialization

    override init() {
        super.init()
        checkAuthorization()
    }

    // MARK: - Authorization

    /// Requests authorization for speech recognition and microphone access
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechStatus else {
            await MainActor.run {
                self.errorMessage = "Speech recognition access denied"
                self.isAuthorized = false
            }
            return false
        }

        // Request microphone authorization
        let micStatus = await AVAudioSession.sharedInstance().requestRecordPermission()

        guard micStatus else {
            await MainActor.run {
                self.errorMessage = "Microphone access denied"
                self.isAuthorized = false
            }
            return false
        }

        await MainActor.run {
            self.isAuthorized = true
            self.errorMessage = nil
        }

        return true
    }

    private func checkAuthorization() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        isAuthorized = speechStatus == .authorized
    }

    // MARK: - Recording Control

    /// Starts recording and speech recognition
    /// - Parameters:
    ///   - language: The language to recognize (defaults to current locale)
    ///   - continuous: Whether to continue recognizing after pauses
    ///   - onResult: Callback for final transcript
    func startRecording(
        language: Locale.Language? = nil,
        continuous: Bool = false,
        onResult: ((String) -> Void)? = nil
    ) throws {
        // Stop any existing recording
        if isRecording {
            stopRecording()
        }

        // Reset state
        transcript = ""
        errorMessage = nil
        onFinalTranscript = onResult

        // Set up recognizer for the specified language
        let locale = language.map { Locale(identifier: $0.minimalIdentifier) } ?? Locale.current
        recognizer = SFSpeechRecognizer(locale: locale)

        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }

        // Configure audio session
        try setupAudioSession()

        // Create recognition request
        request = SFSpeechAudioBufferRecognitionRequest()

        guard let request = request else {
            throw SpeechRecognitionError.requestCreationFailed
        }

        request.shouldReportPartialResults = true

        // On-device recognition if available (iOS 13+)
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = false
        }

        // Get the audio engine's input node
        let inputNode = audioEngine.inputNode

        // Create and start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                if !continuous {
                    self.stopRecording()
                }

                if isFinal, let finalTranscript = result?.bestTranscription.formattedString {
                    self.onFinalTranscript?(finalTranscript)
                }
            }
        }

        // Configure the audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on audio engine
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            self?.updateAudioLevel(buffer)

            if continuous {
                self?.detectVoiceActivity(buffer)
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    /// Stops recording and speech recognition
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        recognitionTask?.cancel()

        recognitionTask = nil
        request = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func updateAudioLevel(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0.0, min((avgPower + 50) / 50, 1.0))

        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
        }
    }

    private func detectVoiceActivity(_ buffer: AVAudioPCMBuffer) {
        let currentLevel = calculateAudioPower(buffer)

        // Threshold for voice detection (adjust as needed)
        let voiceThreshold: Float = 0.1

        if currentLevel > voiceThreshold {
            // Voice detected
            lastAudioTime = Date()
            silenceTimer?.invalidate()
        } else {
            // Check for prolonged silence
            let silenceDuration = Date().timeIntervalSince(lastAudioTime)

            if silenceDuration > silenceThreshold {
                finalizeCurrentTranscript()
            }
        }
    }

    private func calculateAudioPower(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { abs(channelDataValue[$0]) }

        let average = channelDataValueArray.reduce(0, +) / Float(buffer.frameLength)
        return average
    }

    private func finalizeCurrentTranscript() {
        guard !transcript.isEmpty else { return }

        DispatchQueue.main.async {
            self.onFinalTranscript?(self.transcript)
            self.transcript = ""
        }

        lastAudioTime = Date()
    }

    // MARK: - Cleanup

    deinit {
        stopRecording()
    }
}

// MARK: - Error Types

enum SpeechRecognitionError: LocalizedError {
    case recognizerNotAvailable
    case requestCreationFailed
    case audioEngineError
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available for this language"
        case .requestCreationFailed:
            return "Failed to create speech recognition request"
        case .audioEngineError:
            return "Audio engine error occurred"
        case .notAuthorized:
            return "Speech recognition not authorized"
        }
    }
}

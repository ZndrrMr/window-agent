import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Speech Recognition Service
@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage = ""
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Callback for completed transcriptions
    var onTranscriptionCompleted: ((String) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSpeechRecognizer()
        requestAuthorization()
    }
    
    // MARK: - Setup
    private func setupSpeechRecognizer() {
        speechRecognizer?.delegate = self
        guard speechRecognizer?.isAvailable == true else {
            errorMessage = "Speech recognition is not available on this device"
            return
        }
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                    self?.errorMessage = ""
                case .denied:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition access denied. Please enable in System Settings > Privacy & Security > Speech Recognition."
                case .restricted:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition is restricted on this device"
                case .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition authorization not determined"
                @unknown default:
                    self?.isAuthorized = false
                    self?.errorMessage = "Unknown speech recognition authorization status"
                }
            }
        }
    }
    
    // MARK: - Recording Control
    func startListening() {
        print("🎙️ SpeechService: startListening called. isAuthorized: \(isAuthorized)")
        
        guard isAuthorized else {
            print("🎙️ SpeechService: Not authorized, requesting authorization")
            requestAuthorization()
            return
        }
        
        // Stop any existing recognition
        stopListening()
        
        do {
            try startRecording()
            print("🎙️ SpeechService: Recording started successfully. isListening: \(isListening)")
        } catch {
            print("🎙️ SpeechService: Failed to start recording: \(error)")
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopListening() {
        print("🎙️ SpeechService: stopListening called. Current isListening: \(isListening)")
        
        // Stop audio engine and properly clean up
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove any existing tap on the input node
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        
        print("🎙️ SpeechService: Stopped. isListening now: \(isListening)")
        
        // Trigger completion callback if we have transcribed text
        if !transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("🎙️ SpeechService: Calling transcription completion callback")
            onTranscriptionCompleted?(transcribedText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    // MARK: - Audio Recording
    private func startRecording() throws {
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.failedToCreateRequest
        }
        
        // Configure request for real-time recognition
        recognitionRequest.shouldReportPartialResults = true
        
        // Use on-device recognition if available (more private)
        if #available(macOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Remove any existing tap first (just in case)
        inputNode.removeTap(onBus: 0)
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start speech recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    
                    // If result is final, we can stop
                    if result.isFinal {
                        self?.stopListening()
                    }
                }
                
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self?.stopListening()
                }
            }
        }
        
        isListening = true
        transcribedText = ""
        errorMessage = ""
    }
    
    // MARK: - Cleanup
    deinit {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                errorMessage = "Speech recognition became unavailable"
                stopListening()
            }
        }
    }
}

// MARK: - Custom Errors
enum SpeechRecognitionError: LocalizedError {
    case failedToCreateRequest
    case audioEngineNotRunning
    case recognitionNotAuthorized
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateRequest:
            return "Failed to create speech recognition request"
        case .audioEngineNotRunning:
            return "Audio engine is not running"
        case .recognitionNotAuthorized:
            return "Speech recognition is not authorized"
        }
    }
}
import Foundation
import AVFoundation
import FluidAudio
import SwiftData


@MainActor
@Observable
final class DiarizationManager {
    private var fluidDiarizer: DiarizerManager?
    private var isInitialized = false
    private var audioBuffer: [Float] = []
    private let sampleRate: Float = 16000.0
    
    // Configuration
    var config: DiarizerConfig = DiarizerConfig()
    var isEnabled: Bool = true
    var enableRealTimeProcessing: Bool = false
    
    // State
    var isProcessing = false
    var lastError: (any Error)?
    var processingProgress: Double = 0.0
    
    // Results
    private(set) var lastResult: DiarizationResult?
    
    init(config: DiarizerConfig = DiarizerConfig(), isEnabled: Bool = true, enableRealTimeProcessing: Bool = false) {
        self.config = config
        self.isEnabled = isEnabled
        self.enableRealTimeProcessing = enableRealTimeProcessing
    }
    
    // MARK: - Initialization
    
    func initialize() async throws {
        print("[DiarizationManager] Initializing FluidAudio diarizer...")
        
        guard isEnabled else {
            print("[DiarizationManager] Diarization is disabled in config")
            return
        }
        
        do {
            // Create FluidAudio diarizer with custom config
            let fluidConfig = createFluidAudioConfig()
            fluidDiarizer = DiarizerManager(config: fluidConfig)
            
            // Initialize the diarizer (downloads models if needed)
            try await fluidDiarizer?.initialize()
            
            isInitialized = true
            print("[DiarizationManager] FluidAudio diarizer initialized successfully")
        } catch {
            print("[DiarizationManager] Failed to initialize diarizer: \(error)")
            lastError = error
            throw error
        }
    }
    
    private func createFluidAudioConfig() -> DiarizerConfig {
        return config
    }
    
    // MARK: - Audio Processing
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard isEnabled, isInitialized else { return }
        
        // Convert audio buffer to Float array at 16kHz
        guard let floatSamples = convertBufferToFloatArray(buffer) else {
            print("[DiarizationManager] Failed to convert audio buffer")
            return
        }
        
        // Accumulate audio for batch processing
        audioBuffer.append(contentsOf: floatSamples)
        
        // Process in real-time if enabled and we have enough audio
        if enableRealTimeProcessing && audioBuffer.count >= Int(sampleRate * 10) {
            _ = await processAccumulatedAudio()
        }
    }
    
    func finishProcessing() async -> DiarizationResult? {
        guard isEnabled, isInitialized, !audioBuffer.isEmpty else {
            return nil
        }
        
        return await processAccumulatedAudio()
    }
    
    private func processAccumulatedAudio() async -> DiarizationResult? {
        guard let diarizer = fluidDiarizer, !audioBuffer.isEmpty else {
            return nil
        }
        
        isProcessing = true
        processingProgress = 0.0
        
        do {
            print("[DiarizationManager] Processing \(audioBuffer.count) audio samples...")
            let startTime = Date()
            
            // Perform diarization using FluidAudio
            let fluidResult = try await diarizer.performCompleteDiarization(
                audioBuffer,
                sampleRate: Int(sampleRate)
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            print("[DiarizationManager] Diarization completed in \(processingTime)s")
            
            // Use FluidAudio result directly
            lastResult = fluidResult
            processingProgress = 1.0
            isProcessing = false
            
            // Clear the buffer after processing
            audioBuffer.removeAll()
            
            return fluidResult
            
        } catch {
            print("[DiarizationManager] Diarization failed: \(error)")
            lastError = error
            isProcessing = false
            return nil
        }
    }
    
    // MARK: - Speaker Comparison
    
    func compareSpeakers(audio1: [Float], audio2: [Float]) async throws -> Float {
        guard let diarizer = fluidDiarizer else {
            throw DiarizationError.notInitialized
        }
        
        return try await diarizer.compareSpeakers(audio1: audio1, audio2: audio2)
    }
    
    // MARK: - Utility Methods
    
    private func convertBufferToFloatArray(_ buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        // Convert to mono and resample to 16kHz if needed
        var samples: [Float] = []
        
        if buffer.format.sampleRate != 16000 {
            // Simple downsampling - in production, use proper resampling
            let ratio = buffer.format.sampleRate / 16000.0
            let targetFrameCount = Int(Double(frameCount) / ratio)
            
            for frame in 0..<targetFrameCount {
                let sourceFrame = Int(Double(frame) * ratio)
                if sourceFrame < frameCount {
                    var sample: Float = 0.0
                    for channel in 0..<channelCount {
                        sample += channelData[channel][sourceFrame]
                    }
                    samples.append(sample / Float(channelCount))
                }
            }
        } else {
            // Already at 16kHz, just convert to mono
            for frame in 0..<frameCount {
                var sample: Float = 0.0
                for channel in 0..<channelCount {
                    sample += channelData[channel][frame]
                }
                samples.append(sample / Float(channelCount))
            }
        }
        
        return samples
    }
    
    
    // MARK: - Reset and Cleanup
    
    func reset() {
        audioBuffer.removeAll()
        lastResult = nil
        lastError = nil
        processingProgress = 0.0
        isProcessing = false
    }
    
    func validateAudio(_ audio: [Float]) async -> AudioValidationResult? {
        guard let diarizer = fluidDiarizer else { return nil }
        return diarizer.validateAudio(audio)
    }
}

// MARK: - Error Types

enum DiarizationError: LocalizedError {
    case notInitialized
    case processingFailed(String)
    case invalidAudioFormat
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Diarization manager not initialized"
        case .processingFailed(let message):
            return "Diarization processing failed: \(message)"
        case .invalidAudioFormat:
            return "Invalid audio format for diarization"
        case .configurationError(let message):
            return "Diarization configuration error: \(message)"
        }
    }
}

// MARK: - Progress Tracking

extension DiarizationManager {
    func estimateProgress(for audioLength: TimeInterval) -> Double {
        // Rough estimation based on typical processing speed
        let estimatedProcessingTime = audioLength * 0.1 // 10% of real-time
        return min(processingProgress / estimatedProcessingTime, 1.0)
    }
}


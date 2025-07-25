import AVFoundation
import Foundation
import SwiftUI
import SwiftData
import FluidAudio

class Recorder {
    private var outputContinuation: AsyncStream<AudioData>.Continuation?

    // Separate engines for recording and playback to avoid conflicts
    private let recordingEngine: AVAudioEngine
    private let playbackEngine: AVAudioEngine

    private let transcriber: SpokenWordTranscriber
    private var audioFile: AVAudioFile?
    var playerNode: AVAudioPlayerNode?

    var memo: Binding<Memo>
    private let url: URL
    
    // Diarization support
    private let diarizationManager: DiarizationManager
    private let modelContext: ModelContext

    init(transcriber: SpokenWordTranscriber, memo: Binding<Memo>, diarizationManager: DiarizationManager, modelContext: ModelContext) {
        self.recordingEngine = AVAudioEngine()
        self.playbackEngine = AVAudioEngine()
        self.transcriber = transcriber
        self.memo = memo
        self.diarizationManager = diarizationManager
        self.modelContext = modelContext
        self.url = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension("wav")
    }

    func record() async throws {
        print("DEBUG [Recorder]: Starting recording session")

        // Update memo URL on main actor - capture specific values to avoid sending self
        let memoURLBinding = memo.url
        let recordingURL = url
        await MainActor.run {
            memoURLBinding.wrappedValue = recordingURL
        }

        guard await isAuthorized() else {
            print("DEBUG [Recorder]: Recording authorization failed")
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        // Set up audio session for both iOS and macOS
        do {
            try setUpAudioSession()
            print("DEBUG [Recorder]: Audio session setup completed")
        } catch {
            print("DEBUG [Recorder]: Audio session setup failed: \(error)")
            throw error
        }

        do {
            try await transcriber.setUpTranscriber()
            print("DEBUG [Recorder]: Transcriber setup completed")
        } catch {
            print("DEBUG [Recorder]: Transcriber setup failed: \(error)")
            throw error
        }

        // Initialize diarization manager
        do {
            try await diarizationManager.initialize()
            print("DEBUG [Recorder]: Diarization manager initialized")
        } catch {
            print("DEBUG [Recorder]: Diarization setup failed: \(error)")
            // Continue without diarization if it fails
        }

        print("DEBUG [Recorder]: Audio session and transcriber set up successfully")

        // Create audio stream and process it
        do {
            let audioStreamSequence = try await audioStream()
            for await audioData in audioStreamSequence {
                // Process the buffer for transcription
                try await self.transcriber.streamAudioToTranscriber(audioData.buffer)
                
                // Also process for diarization
                await self.diarizationManager.processAudioBuffer(audioData.buffer)
            }
        } catch {
            print("DEBUG [Recorder]: Audio streaming failed: \(error)")
            throw error
        }
    }

    func stopRecording() async throws {
        print("DEBUG [Recorder]: Stopping recording session")

        // Stop the recording engine if it's running
        if recordingEngine.isRunning {
            recordingEngine.stop()
            print("DEBUG [Recorder]: Recording engine stopped")
        }

        // Remove tap safely
        recordingEngine.inputNode.removeTap(onBus: 0)

        // Update memo completion status - capture specific binding to avoid sending self
        let memoIsDoneBinding = memo.isDone
        await MainActor.run {
            memoIsDoneBinding.wrappedValue = true
        }

        // Clean up continuation
        outputContinuation?.finish()
        outputContinuation = nil
        print("DEBUG [Recorder]: Audio stream continuation finished")

        do {
            try await transcriber.finishTranscribing()
            print("DEBUG [Recorder]: Transcription finalized")
        } catch {
            print("DEBUG [Recorder]: Error finalizing transcription: \(error)")
            throw error
        }

        // Process final diarization
        await processFinalDiarization()

        print("DEBUG [Recorder]: Recording stopped and transcription finalized")
    }

    func pauseRecording() {
        print("DEBUG [Recorder]: Pausing recording")
        recordingEngine.pause()
    }

    func resumeRecording() throws {
        print("DEBUG [Recorder]: Resuming recording")
        try recordingEngine.start()
    }

    #if os(iOS)
        func setUpAudioSession() throws {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
    #else
        // macOS audio session setup
        func setUpAudioSession() throws {
            print("DEBUG [Recorder]: Setting up macOS audio session")

            // Reset recording engine if needed
            if recordingEngine.isRunning {
                print("DEBUG [Recorder]: Stopping recording engine for reset")
                recordingEngine.stop()
            }
            recordingEngine.reset()

            // Request microphone access
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                print("DEBUG [Recorder]: Audio access already authorized")
            case .notDetermined:
                print("DEBUG [Recorder]: Audio access not determined, requesting...")
            // This will be handled by the isAuthorized() check in record()
            case .denied, .restricted:
                print("DEBUG [Recorder]: Audio access denied or restricted")
                throw TranscriptionError.failedToSetupRecognitionStream
            @unknown default:
                print("DEBUG [Recorder]: Unknown audio authorization status")
                throw TranscriptionError.failedToSetupRecognitionStream
            }
        }
    #endif

    private func audioStream() async throws -> AsyncStream<AudioData> {
        try setupRecordingEngine()

        recordingEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: recordingEngine.inputNode.outputFormat(forBus: 0)
        ) { [weak self] (buffer, time) in
            guard let self else { return }
            self.writeBufferToDisk(buffer: buffer)
            // Wrap in AudioData to make it Sendable for Swift 6
            let audioData = AudioData(buffer: buffer, time: time)
            self.outputContinuation?.yield(audioData)
        }

        recordingEngine.prepare()
        try recordingEngine.start()
        print("DEBUG [Recorder]: Recording engine started successfully")

        return AsyncStream(AudioData.self, bufferingPolicy: .unbounded) { continuation in
            self.outputContinuation = continuation
        }
    }

    private func setupRecordingEngine() throws {
        print("DEBUG [Recorder]: Setting up recording engine")

        // Stop and reset if already running
        if recordingEngine.isRunning {
            print("DEBUG [Recorder]: Stopping existing recording engine")
            recordingEngine.stop()
        }

        // Remove any existing taps first
        recordingEngine.inputNode.removeTap(onBus: 0)

        // Reset the engine to clean state
        recordingEngine.reset()

        let inputFormat = recordingEngine.inputNode.outputFormat(forBus: 0)
        print("DEBUG [Recorder]: Input format: \(inputFormat)")

        // Create audio file for writing
        let inputSettings = inputFormat.settings
        do {
            self.audioFile = try AVAudioFile(forWriting: url, settings: inputSettings)
            print("DEBUG [Recorder]: Audio file created successfully at: \(url)")
        } catch {
            print("DEBUG [Recorder]: Failed to create audio file: \(error)")
            throw error
        }
    }

    private func writeBufferToDisk(buffer: AVAudioPCMBuffer) {
        do {
            try audioFile?.write(from: buffer)
        } catch {
            print("DEBUG [Recorder]: File writing error: \(error)")
        }
    }

    func playRecording() async {
        guard let audioFile = audioFile else {
            return
        }

        // Stop any existing playback
        await stopPlaying()

        // Setup playback engine
        playerNode = AVAudioPlayerNode()
        guard let playerNode = playerNode else {
            return
        }

        playbackEngine.attach(playerNode)
        playbackEngine.connect(
            playerNode,
            to: playbackEngine.outputNode,
            format: audioFile.processingFormat
        )

        playerNode.scheduleFile(
            audioFile,
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { _ in
            // Playback completed
        }

        do {
            try playbackEngine.start()
            playerNode.play()
        } catch {
            print("[Recorder]: Error starting playback engine: \(error.localizedDescription)")
        }
    }

    func stopPlaying() async {
        // Stop the player node
        playerNode?.stop()

        // Stop the playback engine
        if playbackEngine.isRunning {
            playbackEngine.stop()
        }

        // Clean up the player node
        if let playerNode = playerNode {
            playbackEngine.detach(playerNode)
            self.playerNode = nil
        }
    }
    
    // MARK: - Diarization Processing
    
    private func processFinalDiarization() async {
        print("DEBUG [Recorder]: Processing final diarization...")
        
        guard let diarizationResult = await diarizationManager.finishProcessing() else {
            print("DEBUG [Recorder]: No diarization result available")
            return
        }
        
        print(
            "DEBUG [Recorder]: Diarization completed with \(diarizationResult.segments.count) segments and \(diarizationResult.segments) speakers"
        )
        
        // Update memo with diarization results on the main actor
        await MainActor.run {
            memo.wrappedValue.updateWithDiarizationResult(diarizationResult, in: modelContext)
            
            // If we have speaker segments, try to align them with transcription text
            if !diarizationResult.segments.isEmpty {
                alignTranscriptionWithSpeakers(diarizationResult)
            }
        }
    }
    
    private func alignTranscriptionWithSpeakers(_ diarizationResult: DiarizationResult) {
        print("DEBUG [Recorder]: Aligning transcription with speaker segments...")
        
        // Get the current transcription text
        let transcriptionText = String(memo.wrappedValue.text.characters)
        
        // Simple alignment: distribute text proportionally across speaker segments
        // In a production app, you'd want more sophisticated alignment
        let sortedSegments = diarizationResult.segments.sorted(by: { $0.startTimeSeconds < $1.startTimeSeconds })
        let totalDuration = sortedSegments.last?.endTimeSeconds ?? 1.0
        
        var textIndex = 0
        
        for segment in sortedSegments {
            let segmentDuration = segment.endTimeSeconds - segment.startTimeSeconds
            let segmentPortion = segmentDuration / totalDuration
            let segmentTextLength = Int(Double(transcriptionText.count) * Double(segmentPortion))
            
            let endIndex = min(textIndex + segmentTextLength, transcriptionText.count)
            
            if textIndex < transcriptionText.count {
                let startStringIndex = transcriptionText.index(transcriptionText.startIndex, offsetBy: textIndex)
                let endStringIndex = transcriptionText.index(transcriptionText.startIndex, offsetBy: endIndex)
                let segmentText = String(transcriptionText[startStringIndex..<endStringIndex])
                
                // Update the speaker segment with aligned text
                if let speakerSegment = memo.wrappedValue.speakerSegments.first(where: { 
                    $0.speakerId == segment.speakerId && 
                    abs($0.startTime - TimeInterval(segment.startTimeSeconds)) < 0.1 
                }) {
                    speakerSegment.text = segmentText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                textIndex = endIndex
            }
        }
        
        print("DEBUG [Recorder]: Text alignment completed")
    }
}

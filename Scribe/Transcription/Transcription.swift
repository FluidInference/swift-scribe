import Foundation
import Speech
import SwiftUI

@Observable
@MainActor
final class SpokenWordTranscriber {
    private let inputSequence: AsyncStream<AnalyzerInput>
    private let inputBuilder: AsyncStream<AnalyzerInput>.Continuation
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), any Error>?

    static let green = Color(red: 0.36, green: 0.69, blue: 0.55).opacity(0.8)  // #5DAF8D

    // The format of the audio.
    var analyzerFormat: AVAudioFormat?

    let converter = BufferConverter()
    var downloadProgress: Progress?

    let memo: Binding<Memo>

    var volatileTranscript: AttributedString = ""
    var finalizedTranscript: AttributedString = ""

    static let locale = Locale(
        components: .init(languageCode: .english, script: nil, languageRegion: .unitedStates))
    
    // Fallback locales to try when the preferred locale isn't available
    static let fallbackLocales = [
        Locale(components: .init(languageCode: .english, script: nil, languageRegion: .unitedStates)),
        Locale(components: .init(languageCode: .english, script: nil, languageRegion: .unitedKingdom)),
        Locale(components: .init(languageCode: .english, script: nil, languageRegion: .canada)),
        Locale(components: .init(languageCode: .english, script: nil, languageRegion: .australia)),
        Locale(identifier: "en-US"),
        Locale(identifier: "en"),
        Locale.current
    ]

    init(memo: Binding<Memo>) {
        print(
            "[Transcriber DEBUG]: Initializing SpokenWordTranscriber with locale: \(SpokenWordTranscriber.locale.identifier)"
        )
        self.memo = memo
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputSequence = stream
        self.inputBuilder = continuation
    }

    func setUpTranscriber() async throws {
        print("[Transcriber DEBUG]: Starting transcriber setup...")

        transcriber = SpeechTranscriber(
            locale: SpokenWordTranscriber.locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange])

        guard let transcriber else {
            print("[Transcriber DEBUG]: ERROR - Failed to create SpeechTranscriber")
            throw TranscriptionError.failedToSetupRecognitionStream
        }
        print("[Transcriber DEBUG]: SpeechTranscriber created successfully")

        analyzer = SpeechAnalyzer(modules: [transcriber])
        print("[Transcriber DEBUG]: SpeechAnalyzer created with transcriber module")

        do {
            print("[Transcriber DEBUG]: Ensuring model is available...")
            try await ensureModel(transcriber: transcriber, locale: SpokenWordTranscriber.locale)
            print("[Transcriber DEBUG]: Model check completed successfully")
        } catch let error as TranscriptionError {
            print("[Transcriber DEBUG]: Model setup failed with error: \(error.descriptionString)")
            throw error
        }

        self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [
            transcriber
        ])
        print("[Transcriber DEBUG]: Best audio format: \(String(describing: analyzerFormat))")

        guard analyzerFormat != nil else {
            print("[Transcriber DEBUG]: ERROR - No compatible audio format found")
            throw TranscriptionError.invalidAudioDataType
        }

        recognizerTask = Task {
            print("[Transcriber DEBUG]: Starting recognition task...")
            do {
                print("[Transcriber DEBUG]: About to start listening for transcription results...")
                var resultCount = 0
                for try await case let result in transcriber.results {
                    resultCount += 1
                    let text = result.text
                    if result.isFinal {
                        finalizedTranscript += text
                        volatileTranscript = ""
                        updateMemoWithNewText(withFinal: text)
                    } else {
                        volatileTranscript = text
                        volatileTranscript.foregroundColor = .purple.opacity(0.5)
                    }
                }
                print(
                    "[Transcriber DEBUG]: Recognition task completed normally after \(resultCount) results"
                )
            } catch {
                print(
                    "[Transcriber DEBUG]: ERROR - Speech recognition failed: \(error.localizedDescription)"
                )
            }
        }

        do {
            try await analyzer?.start(inputSequence: inputSequence)
            print("[Transcriber DEBUG]: SpeechAnalyzer started successfully")
        } catch {
            print(
                "[Transcriber DEBUG]: ERROR - Failed to start SpeechAnalyzer: \(error.localizedDescription)"
            )
            throw error
        }
    }

    func updateMemoWithNewText(withFinal str: AttributedString) {
        print("[Transcriber DEBUG]: Updating memo with finalized text: '\(str)'")
        memo.text.wrappedValue.append(str)
        print(
            "[Transcriber DEBUG]: Memo updated, current memo text length: \(memo.text.wrappedValue.characters.count)"
        )
    }

    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let analyzerFormat else {
            print("[Transcriber DEBUG]: ERROR - No analyzer format available")
            throw TranscriptionError.invalidAudioDataType
        }

        let converted = try self.converter.convertBuffer(buffer, to: analyzerFormat)

        let input = AnalyzerInput(buffer: converted)
        inputBuilder.yield(input)
    }

    public func finishTranscribing() async throws {
        print("[Transcriber DEBUG]: Finishing transcription...")
        inputBuilder.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil
        print("[Transcriber DEBUG]: Transcription finished and cleaned up")
    }

    /// Reset the transcriber for a new recording session
    /// This clears existing transcripts when restarting recording
    public func reset() {
        print("[Transcriber DEBUG]: Resetting transcriber - clearing transcripts")
        volatileTranscript = ""
        finalizedTranscript = ""
    }
}

extension SpokenWordTranscriber {
    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        print("[Transcriber DEBUG]: Checking model availability for locale: \(locale.identifier)")

        // First try to download/install any needed assets
        print("[Transcriber DEBUG]: Checking for required downloads...")
        try await downloadIfNeeded(for: transcriber)
        
        // Check supported locales
        let supportedLocales = await SpeechTranscriber.supportedLocales
        print("[Transcriber DEBUG]: Found \(supportedLocales.count) supported locales")
        
        // If no locales are supported, try fallback approach
        if supportedLocales.isEmpty {
            print("[Transcriber DEBUG]: WARNING - No supported locales found. Trying fallback locales...")
            
            // Try each fallback locale
            for fallbackLocale in SpokenWordTranscriber.fallbackLocales {
                print("[Transcriber DEBUG]: Trying fallback locale: \(fallbackLocale.identifier)")
                do {
                    try await allocateLocale(locale: fallbackLocale)
                    print("[Transcriber DEBUG]: Successfully allocated fallback locale: \(fallbackLocale.identifier)")
                    return
                } catch {
                    print("[Transcriber DEBUG]: Fallback locale \(fallbackLocale.identifier) failed: \(error)")
                    continue
                }
            }
            
            print("[Transcriber DEBUG]: All fallback locales failed")
            throw TranscriptionError.localeNotSupported
        }
        
        // Check if preferred locale is supported
        var localeToUse = locale
        if await supported(locale: locale) {
            print("[Transcriber DEBUG]: Preferred locale is supported: \(locale.identifier)")
        } else {
            print("[Transcriber DEBUG]: Preferred locale not supported, trying fallbacks...")
            
            // Try to find a supported fallback locale
            var foundSupportedLocale = false
            for fallbackLocale in SpokenWordTranscriber.fallbackLocales {
                if await supported(locale: fallbackLocale) {
                    print("[Transcriber DEBUG]: Found supported fallback locale: \(fallbackLocale.identifier)")
                    localeToUse = fallbackLocale
                    foundSupportedLocale = true
                    break
                }
            }
            
            guard foundSupportedLocale else {
                print("[Transcriber DEBUG]: ERROR - No supported locale found among fallbacks")
                throw TranscriptionError.localeNotSupported
            }
        }

        if await installed(locale: localeToUse) {
            print("[Transcriber DEBUG]: Model already installed for locale: \(localeToUse.identifier)")
        } else {
            print("[Transcriber DEBUG]: Model not installed for locale: \(localeToUse.identifier)")
        }

        // Always ensure locale is allocated after installation/download
        try await allocateLocale(locale: localeToUse)
    }

    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        
        // Check different locale identifier formats
        let localeId = locale.identifier
        let localeBCP47 = locale.identifier(.bcp47)
        
        // Check with different formatting approaches
        let isSupported = supported.contains { supportedLocale in
            supportedLocale.identifier == localeId ||
            supportedLocale.identifier(.bcp47) == localeBCP47 ||
            supportedLocale.identifier == "en-US" ||
            supportedLocale.identifier(.bcp47) == "en-US"
        }
        
        print(
            "[Transcriber DEBUG]: Supported locales check - locale: \(localeId), bcp47: \(localeBCP47), supported: \(isSupported)"
        )
        print(
            "[Transcriber DEBUG]: All supported locales: \(supported.map { "\($0.identifier) (\($0.identifier(.bcp47)))" })"
        )
        
        // If no locales are supported at all, this indicates a system issue
        if supported.isEmpty {
            print("[Transcriber DEBUG]: WARNING - No supported locales found, this may indicate a system configuration issue")
        }
        
        return isSupported
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        let isInstalled = installed.map { $0.identifier(.bcp47) }.contains(
            locale.identifier(.bcp47))
        print(
            "[Transcriber DEBUG]: Installed locales check - locale: \(locale.identifier), installed: \(isInstalled)"
        )
        print(
            "[Transcriber DEBUG]: All installed locales: \(installed.map { $0.identifier(.bcp47) })"
        )
        return isInstalled
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        print("[Transcriber DEBUG]: Checking if download is needed...")
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module])
        {
            print("[Transcriber DEBUG]: Download required, starting asset installation...")
            self.downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
            print("[Transcriber DEBUG]: Asset download and installation completed")
        } else {
            print("[Transcriber DEBUG]: No download needed")
        }
    }

    func allocateLocale(locale: Locale) async throws {
        print("[Transcriber DEBUG]: Checking if locale is already allocated: \(locale.identifier)")
        let allocated = await AssetInventory.allocatedLocales
        print(
            "[Transcriber DEBUG]: Currently allocated locales: \(allocated.map { $0.identifier })")

        if allocated.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
            print("[Transcriber DEBUG]: Locale already allocated: \(locale.identifier)")
            return
        }

        print("[Transcriber DEBUG]: Allocating locale: \(locale.identifier)")
        try await AssetInventory.allocate(locale: locale)
        print("[Transcriber DEBUG]: Locale allocated successfully: \(locale.identifier)")
    }

    func deallocate() async {
        print("[Transcriber DEBUG]: Deallocating locales...")
        let allocated = await AssetInventory.allocatedLocales
        print("[Transcriber DEBUG]: Allocated locales: \(allocated.map { $0.identifier })")
        for locale in allocated {
            await AssetInventory.deallocate(locale: locale)
        }
        print("[Transcriber DEBUG]: Deallocation completed")
    }
}

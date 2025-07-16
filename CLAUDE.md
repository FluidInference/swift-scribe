# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Swift Scribe is an AI-powered speech-to-text transcription application built exclusively for iOS 26/macOS 26+ using Apple's latest frameworks. It provides real-time voice transcription, on-device AI processing, speaker diarization, and intelligent note-taking with complete privacy protection.

## Essential Development Commands

### Standard Xcode Project Commands

**Building and Running:**
```bash
# Open project in Xcode
open SwiftScribe.xcodeproj

# Build from command line (requires Xcode)
xcodebuild -project SwiftScribe.xcodeproj -scheme SwiftScribe -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Build for macOS
xcodebuild -project SwiftScribe.xcodeproj -scheme SwiftScribe -destination 'platform=macOS' build

# Clean build folder
xcodebuild clean -project SwiftScribe.xcodeproj -scheme SwiftScribe
```

**Testing:**
```bash
# Run tests from command line
xcodebuild test -project SwiftScribe.xcodeproj -scheme SwiftScribe -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests for macOS
xcodebuild test -project SwiftScribe.xcodeproj -scheme SwiftScribe -destination 'platform=macOS'
```

**Swift Package Manager Integration:**
```bash
# Reset Swift Package Manager cache if dependencies have issues
rm -rf SwiftScribe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
# Then rebuild in Xcode to re-resolve packages
```

## Critical System Requirements

**IMPORTANT**: This project requires bleeding-edge Apple platforms:
- **iOS 26 Beta or newer** (will NOT work on iOS 25 or earlier)
- **macOS 26 Beta or newer** (will NOT work on macOS 25 or earlier)
- **Xcode Beta** with Swift 6.2+ toolchain
- **Apple Developer Account** with beta access

## High-Level Architecture

### Core Application Structure

**SwiftUI + SwiftData + Modern Concurrency Architecture:**
- Built entirely with SwiftUI for cross-platform UI
- SwiftData for object persistence (Core Data successor)
- Async/await and actors for concurrent operations
- Observable pattern using Swift 5.9+ `@Observable` macro

### Key Components Hierarchy

1. **App Layer** (`ScribeApp.swift`)
   - Main app entry point with SwiftData model container setup
   - Configures shared model context for memo persistence

2. **View Layer** (`Views/`)
   - `ContentView.swift`: Navigation split view (memo list + transcript detail)
   - `TranscriptView.swift`: Core recording interface with live transcription
   - `SettingsView.swift`: App configuration and preferences
   - Conditional compilation for iOS vs macOS UI differences

3. **Model Layer** (`Models/`)
   - `MemoModel.swift`: Core `Memo` class with SwiftData persistence, AI enhancement, and speaker attribution
   - `SpeakerModels.swift`: `Speaker` and `SpeakerSegment` models for diarization
   - `AppSettings.swift`: Observable settings for themes and diarization preferences

4. **Audio Processing** (`Audio/`)
   - `Recorder.swift`: Dual `AVAudioEngine` architecture (recording + playback engines)
   - `DiarizationManager.swift`: FluidAudio integration for real-time speaker identification

5. **Speech & AI** (`Transcription/` + `Helpers/`)
   - `Transcription.swift`: Apple Speech framework with async stream processing
   - `FoundationModelsHelper.swift`: On-device AI text generation using Apple's FoundationModels

### Apple Framework Dependencies

**Core Frameworks:**
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Object persistence with `@Model` classes
- **Speech**: Real-time speech recognition with streaming
- **AVFoundation**: Audio recording, playback, and processing
- **FoundationModels**: On-device AI text generation (iOS 18+/macOS 15+)

**External Dependencies:**
- **FluidAudio**: Speaker diarization library for advanced speaker separation
  - Repository: `https://github.com/FluidInference/FluidAudio/`
  - Provides `DiarizerManager`, `DiarizationResult`, `TimedSpeakerSegment`

### Advanced Technical Features

1. **Dual Audio Engine Architecture**
   - Separate `AVAudioEngine` instances for recording and playback
   - Prevents conflicts and allows simultaneous recording/playback
   - Real-time audio processing with buffer management

2. **Rich Attribution System**
   - Custom `AttributedString` extensions for speaker identification
   - Color-coded text based on speaker identification
   - Confidence scoring and metadata embedding
   - Timeline-based character position mapping

3. **Real-Time Processing Pipeline**
   - Streaming transcription with live text updates
   - Optional concurrent speaker diarization
   - On-device AI enhancement for summaries and titles
   - Async actors for thread-safe audio processing

4. **Cross-Platform Considerations**
   - Conditional compilation using `#if os(iOS)` and `#if os(macOS)`
   - Platform-specific UI adaptations (navigation styles, toolbars)
   - Shared business logic with platform-specific presentation

## Development Guidelines

### Code Patterns and Conventions

**SwiftUI Observable Pattern:**
```swift
// Use @Observable classes for state management
@Observable
class AppSettings {
    var isDiarizationEnabled: Bool = false
    var selectedTheme: Theme = .automatic
}

// Inject via environment
.environment(settings)
```

**SwiftData Model Pattern:**
```swift
// Use @Model for persistent objects
@Model
final class Memo {
    var title: String
    var text: AttributedString
    @Transient var diarizationResult: DiarizationResult?
    
    // Relationships
    var speakerSegments: [SpeakerSegment] = []
}
```

**Async/Await Audio Processing:**
```swift
// Use structured concurrency for audio operations
Task {
    for await transcription in transcriptionStream {
        await MainActor.run {
            // Update UI on main thread
        }
    }
}
```

### Important Implementation Notes

1. **AttributedString Usage**: The app heavily uses `AttributedString` for rich text with speaker attribution. Custom attribute keys are defined for speaker metadata.

2. **Speaker Diarization Integration**: Optional FluidAudio integration provides real-time speaker identification. Results are stored as separate `SpeakerSegment` entities linked to memos.

3. **AI Enhancement**: Uses Apple's FoundationModels for on-device text generation. Never sends data to external servers - completely privacy-focused.

4. **Cross-Platform UI**: Careful use of conditional compilation for iOS vs macOS differences while maintaining shared business logic.

5. **Audio Permissions**: Requires microphone permissions and speech recognition authorization. Handle permission states gracefully.

### Testing Considerations

- Test on actual devices for speech recognition accuracy
- Mock FluidAudio dependency for unit tests since it requires audio input
- Test speaker diarization accuracy with multiple voice samples
- Verify AttributedString serialization with SwiftData persistence
- Test cross-platform UI on both iOS simulator and macOS

### Common Development Tasks

**Adding New AI Features:**
1. Extend `FoundationModelsHelper.swift` with new generation methods
2. Update `MemoModel.swift` to store AI-generated content
3. Modify `TranscriptView.swift` to trigger AI processing

**Extending Speaker Diarization:**
1. Update `SpeakerModels.swift` for new speaker metadata
2. Modify `DiarizationManager.swift` for additional FluidAudio features
3. Enhance `MemoModel.swift` speaker attribution methods

**UI Enhancements:**
1. Update both iOS and macOS code paths in views
2. Test navigation and layout on different screen sizes
3. Ensure accessibility support for voice-based app

## Project-Specific Requirements

### Development Environment
- **Xcode Beta** with latest Swift 6.2+ toolchain required
- **iOS 26 Beta/macOS 26 Beta** development targets
- **Apple Developer Account** with beta program access for testing

### Capabilities and Entitlements
- Microphone usage for audio recording
- Speech recognition authorization
- Local file system access for audio file storage
- No network permissions required (completely offline operation)

### Performance Considerations
- Optimized for Apple Silicon with MLX framework usage
- Real-time audio processing requires adequate device performance
- Speaker diarization is computationally intensive - consider making it optional
- SwiftData queries for speaker segments should be optimized for large transcripts
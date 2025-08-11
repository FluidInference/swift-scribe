# Swift Scribe - AI-Powered Speech-to-Text Private Transcription App for iOS 26 & macOS 26+
[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)

> **Real-time voice transcription, advanced speaker diarization, on-device AI processing, and intelligent note-taking exclusively for iOS 26 & macOS 26 and above**

Uses Apple's new Foundation Model Framework and SpeechTranscriber. Requires macOS 26 to run and compile the project. The goal is to demonstrate how easy it is now to build local, AI-first apps.

The goal of this is mostly to act as an example for others looking to work with the new models and [FluidAudio](https://github.com/FluidInference/FluidAudio). We will probably not actively maintain this unless there's significant traction. If you have problem, please consider joining our discord to chat more about this! 

[![Discord](https://img.shields.io/badge/Discord-Join%20Chat-7289da.svg)](https://discord.gg/WNsvaCtmDe)

## 🎯 Overview

**Swift Scribe** is a privacy-first, AI-enhanced transcription application built exclusively for iOS 26/macOS 26+ that transforms spoken words into organized, searchable notes with professional-grade speaker identification. Using Apple's latest SpeechAnalyzer and SpeechTranscriber frameworks (available only in iOS 26/macOS 26+) combined with FluidAudio's advanced speaker diarization and on-device Foundation Models, it delivers real-time speech recognition, intelligent speaker attribution, content analysis, and advanced text editing capabilities.


![Swift Scribe Demo - AI Speech-to-Text Transcription](Docs/swift-scribe.gif)

![Swift Scribe Demo - AI Speech-to-Text Transcription iOS](Docs/phone-scribe.gif)

## 🛠 Technical Requirements & Specifications

### **System Requirements**
- **iOS 26 Beta or newer** (REQUIRED - will not work on iOS 25 or earlier)
- **macOS 26 Beta or newer** (REQUIRED - will not work on macOS 25 or earlier)  
- **Xcode Beta** with latest Swift 6.2+ toolchain
- **Swift 6.2+** programming language
- **Apple Developer Account** with beta access to iOS 26/macOS 26
- **Microphone permissions** for speech input


## 🚀 Installation & Setup Guide

### **Development Installation**

1. **Clone the repository:**

   ```bash
   git clone https://github.com/seamlesscompute/swift-scribe
   cd swift-scribe
   ```

2. **Open in Xcode Beta:**

   ```bash
   open SwiftScribe.xcodeproj
   ```

3. **Configure deployment targets** for iOS 26 Beta/macOS 26 Beta or newer

4. **Build and run** using Xcode Beta with Swift 6.2+ toolchain

⚠️ **Note**: Ensure your device is running iOS 26+ or macOS 26+ before installation.

## 📋 Use Cases & Applications

**Transform your workflow with AI-powered transcription:**

### **Business & Professional**
- 📊 **Meeting transcription** with automatic speaker identification and minute generation
- 📝 **Interview recording** with real-time speaker diarization and attribution
- 💼 **Business documentation** with speaker-tagged content and report creation
- 🎯 **Sales call analysis** with participant tracking and follow-up automation

### **Healthcare & Medical**
- 🏥 **Medical dictation** and clinical documentation
- 👨‍⚕️ **Patient interview transcription** with medical terminology
- 📋 **Healthcare report generation** and chart notes
- 🔬 **Research interview analysis** and coding

### **Education & Academic**
- 🎓 **Lecture transcription** with chapter segmentation
- 📚 **Study note creation** from audio recordings
- 🔍 **Research interview analysis** with theme identification
- 📖 **Language learning** with pronunciation feedback

### **Legal & Compliance**
- ⚖️ **Court proceeding transcription** with timestamp accuracy
- 📑 **Deposition recording** and legal documentation
- 🏛️ **Legal research** and case note compilation
- 📋 **Compliance documentation** and audit trails

### **Content Creation & Media**
- 🎙️ **Podcast transcription** with automatic speaker labeling and show note generation
- 🎬 **Video content scripting** with professional speaker diarization
- ✍️ **Article writing** from multi-speaker voice recordings
- 📺 **Content creation workflows** with speaker-attributed production notes

### **Accessibility & Inclusion**
- 🦻 **Real-time captions** for hearing-impaired users
- 🗣️ **Speech accessibility tools** with customizable formatting
- 🌐 **Multi-language accessibility** support
- 🎯 **Assistive technology integration**

## 🏗 Project Architecture & Code Structure

```
Scribe/                     # Core application logic and modules
├── Audio/                  # Audio capture, processing, and FluidAudio speaker diarization
├── Transcription/         # SpeechAnalyzer and SpeechTranscriber implementation
├── AI/                    # Foundation Models integration and AI processing
├── Views/                 # SwiftUI interface with rich text editing
├── Models/                # Data models for memos, transcription, speakers, and AI
├── Storage/               # Local data persistence and model management
└── Extensions/            # Swift extensions and utilities
```

**Key Components:**

- **Audio Engine** - Real-time audio capture and preprocessing
- **Speech Pipeline** - SpeechAnalyzer integration and transcription flow
- **Speaker Diarization** - FluidAudio integration for professional speaker identification
- **AI Processing** - Foundation Models for content analysis
- **Rich Text System** - AttributedString with speaker attribution and advanced formatting
- **Data Layer** - SwiftData integration with speaker models and local storage

## ⭐ Advanced Features

### **🎤 Professional Speaker Diarization**
- **FluidAudio Integration**: Industry-grade speaker identification and clustering
- **Research-Grade Performance**: Competitive with academic benchmarks (17.7% DER on AMI dataset)
- **Real-time Processing**: Live speaker identification during recording with minimal latency
- **Speaker Attribution**: Color-coded transcription with confidence scores and timeline mapping

### **🧠 Intelligent Speaker Management**
- **Automatic Speaker Detection**: No manual configuration required
- **Speaker Persistence**: Consistent speaker identification across recording sessions  
- **Visual Attribution**: Rich text formatting with speaker-specific colors and metadata
- **Speaker Analytics**: Detailed insights into speaking patterns and participation

### **🔒 Privacy-First Architecture**
- **Fully On-Device**: All processing happens locally - no cloud dependencies
- **Zero Data Transmission**: Audio and speaker data never leave your device
- **Secure Storage**: Speaker embeddings and models stored securely with SwiftData
- **Complete Offline Operation**: Works without internet connectivity

## 🗺 Development Roadmap & Future Features

### **Phase 1: Core Features** ✅ **COMPLETED**

- ✅ Real-time speech transcription
- ✅ On-device AI processing  
- ✅ Rich text editing
- ✅ **Professional speaker diarization** with FluidAudio integration
- ✅ **Speaker attribution** and visual formatting

### **Phase 2: Advanced Features** 

- 🔊 **Output audio tap** for system audio capture
- 🌐 **Enhanced multi-language** support
- 📊 **Advanced analytics** and speaker insights
- 🎯 **Speaker voice profiles** and personalization

## 📄 License & Legal

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for complete details.

## 🙏 Acknowledgments & Credits

- **Apple WWDC 2025** sessions on SpeechAnalyzer, Foundation Models, and Rich Text editing
- **Apple Developer Frameworks** - SpeechAnalyzer, Foundation Models, Rich Text Editor
- **FluidAudio** - Professional speaker diarization and voice identification technology

## 🚀 Getting Started with AI Development Tools

**For Cursor & Windsurf IDE users:** Leverage AI agents to explore the comprehensive documentation in the `Docs/` directory, featuring complete WWDC 2025 session transcripts covering:

- 🎤 **SpeechAnalyzer & SpeechTranscriber** API implementation guides
- 🤖 **Foundation Models** framework integration
- ✏️ **Rich Text Editor** advanced capabilities  
- 🔊 **Audio processing** improvements and optimizations

---

**⭐ Star this repo** if you find it useful! | **🔗 Share** with developers interested in AI-powered speech transcription

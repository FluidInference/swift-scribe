# Slipbox Scribe - AI-Powered Speech-to-Text Private Transcription App for iOS 26 & macOS 26+

> **Real-time voice transcription, on-device AI processing, and intelligent note-taking exclusively for iOS 26 & macOS 26 and above**

⚠️ **COMPATIBILITY NOTICE**: This application requires iOS 26 Beta/macOS 26 Beta or newer versions. It will NOT work on earlier iOS/macOS versions due to SpeechAnalyzer framework dependencies.

An advanced iOS/macOS speech-to-text application that leverages Apple's cutting-edge SpeechAnalyzer framework, Foundation Models AI, and Rich Text Editor for intelligent voice note-taking, meeting transcription, and knowledge management.

## 🎯 Overview

**Slipbox Scribe** is a privacy-first, AI-enhanced transcription application built exclusively for iOS 26/macOS 26+ that transforms spoken words into organized, searchable notes. Using Apple's latest SpeechAnalyzer and SpeechTranscriber frameworks (available only in iOS 26/macOS 26+) combined with on-device Foundation Models, it delivers real-time speech recognition, intelligent content analysis, and advanced text editing capabilities.

**Key Technologies:** SpeechAnalyzer • Foundation Models • Rich Text Editor • SwiftUI • Swift 6.2+ • On-Device AI

✅ **100% On-Device Processing** - No cloud dependencies, complete privacy  
✅ **Real-Time Transcription** - Live speech-to-text with volatile and finalized results  
✅ **AI-Powered Analysis** - Intelligent content organization and insights  
✅ **Multi-Language Support** - International speech recognition capabilities  
✅ **Rich Text Editing** - Advanced formatting with AttributedString  

![Slipbox Scribe Demo - AI Speech-to-Text Transcription](Docs/slipbox-scribe.gif)

## 📱 Screenshots & Demo

<table>
  <tr>
    <td><img src="Docs/ios.png" alt="iOS Speech-to-Text App Interface - Real-time Transcription" width="300"/></td>
    <td><img src="Docs/ios2.png" alt="iOS AI Note-Taking App - Rich Text Editor" width="300"/></td>
  </tr>
</table>

## ⚡ Core Features & Capabilities

### 🎤 **Advanced Speech Recognition**
- **Real-time transcription** using Apple's SpeechAnalyzer framework
- **Long-form audio support** for extended recordings
- **Multi-language speech recognition** with automatic language detection
- **Volatile and finalized results** for immediate feedback
- **High accuracy transcription** optimized for various audio conditions

### 🤖 **On-Device AI Processing**
- **Foundation Models integration** for intelligent content analysis
- **Automatic content organization** and categorization
- **Knowledge graph generation** from transcribed content
- **Smart linking** between related ideas and concepts
- **AI-powered insights** and content suggestions

### ✏️ **Rich Text Editing & Formatting**
- **AttributedString support** for advanced text formatting
- **Custom formatting definitions** and dynamic attributes
- **Rich text editor** with real-time styling
- **Export capabilities** in multiple formats
- **Advanced search** and navigation features

### 🔒 **Privacy & Security**
- **100% on-device processing** - no data transmission
- **Local model storage** and management
- **Privacy-first architecture** with no cloud dependencies
- **Secure data handling** following Apple's best practices

## 🛠 Technical Requirements & Specifications

### **System Requirements**
- **iOS 26 Beta or newer** (REQUIRED - will not work on iOS 25 or earlier)
- **macOS 26 Beta or newer** (REQUIRED - will not work on macOS 25 or earlier)  
- **Xcode Beta** with latest Swift 6.2+ toolchain
- **Swift 6.2+** programming language
- **Apple Developer Account** with beta access to iOS 26/macOS 26
- **Microphone permissions** for speech input

⚠️ **CRITICAL**: SpeechAnalyzer framework is only available in iOS 26/macOS 26+. This app cannot be backported to earlier versions.

### **Framework Dependencies**
- **SpeechAnalyzer & SpeechTranscriber** - Core speech recognition
- **Foundation Models** - On-device AI and ML processing
- **AssetInventory** - Model downloading and management
- **AttributedString** - Rich text handling and formatting
- **AVFoundation** - Audio capture and processing
- **SwiftUI** - Modern declarative user interface

## 🚀 Installation & Setup Guide

### **Development Installation**

1. **Clone the repository:**

   ```bash
   git clone https://github.com/slipboxai/swift-scribe
   cd swift-scribe
   ```

2. **Open in Xcode Beta:**

   ```bash
   open SlipboxScribe.xcodeproj
   ```

3. **Configure deployment targets** for iOS 26 Beta/macOS 26 Beta or newer

4. **Build and run** using Xcode Beta with Swift 6.2+ toolchain

⚠️ **Note**: Ensure your device is running iOS 26+ or macOS 26+ before installation.

## 📋 Use Cases & Applications

**Transform your workflow with AI-powered transcription:**

### **Business & Professional**
- 📊 **Meeting transcription** and automated minute generation
- 📝 **Interview recording** with speaker identification
- 💼 **Business documentation** and report creation
- 🎯 **Sales call analysis** and follow-up automation

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
- 🎙️ **Podcast transcription** and show note generation
- 🎬 **Video content scripting** with speaker identification
- ✍️ **Article writing** from voice recordings
- 📺 **Content creation workflows** and production notes

### **Accessibility & Inclusion**
- 🦻 **Real-time captions** for hearing-impaired users
- 🗣️ **Speech accessibility tools** with customizable formatting
- 🌐 **Multi-language accessibility** support
- 🎯 **Assistive technology integration**

## 🏗 Project Architecture & Code Structure

```
Scribe/                     # Core application logic and modules
├── Audio/                  # Audio capture, processing, and management
├── Transcription/         # SpeechAnalyzer and SpeechTranscriber implementation
├── AI/                    # Foundation Models integration and AI processing
├── Views/                 # SwiftUI interface with rich text editing
├── Models/                # Data models for memos, transcription, and AI
├── Storage/               # Local data persistence and model management
└── Extensions/            # Swift extensions and utilities
```

**Key Components:**
- **Audio Engine** - Real-time audio capture and preprocessing
- **Speech Pipeline** - SpeechAnalyzer integration and transcription flow
- **AI Processing** - Foundation Models for content analysis
- **Rich Text System** - AttributedString and advanced formatting
- **Data Layer** - Core Data integration and local storage

## 🗺 Development Roadmap & Future Features

### **Phase 1: Core Enhancement**
- ✅ Real-time speech transcription
- ✅ On-device AI processing
- ✅ Rich text editing
- 🔄 Enhanced accuracy improvements

### **Phase 2: Advanced Features** 
- 🎯 **Speaker diarization** and voice identification
- 🔊 **Output audio tap** for system audio capture
- 🌐 **Enhanced multi-language** support
- 📊 **Advanced analytics** and insights

### **Phase 3: Platform Expansion**
- 📱 **iOS Shortcuts** integration
- ⌚ **Apple Watch** companion app
- 💻 **macOS menu bar** quick access
- 🔗 **API integration** capabilities

## 🏷 Keywords & Tags

**Primary Keywords:** speech-to-text, voice transcription, iOS 26 app, macOS 26 app, AI transcription, on-device AI, SpeechAnalyzer, Foundation Models, Swift 6.2, real-time transcription

**Secondary Keywords:** voice notes, meeting transcription, speech recognition, AI note-taking, privacy-first transcription, Apple AI frameworks, iOS 26+, macOS 26+, SwiftUI app, beta iOS app

**Technical Tags:** #SpeechAnalyzer #FoundationModels #Swift62 #iOS26 #macOS26 #OnDeviceAI #SpeechToText #VoiceTranscription #RichTextEditor #PrivacyFirst #AppleBeta

## 📄 License & Legal

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for complete details.

## 🙏 Acknowledgments & Credits

- **Apple WWDC 2025** sessions on SpeechAnalyzer, Foundation Models, and Rich Text editing
- **Apple Developer Frameworks** - SpeechAnalyzer, Foundation Models, Rich Text Editor
- **Open Source Community** contributions and feedback

## 🚀 Getting Started with AI Development Tools

**For Cursor & Windsurf IDE users:** Leverage AI agents to explore the comprehensive documentation in the `Docs/` directory, featuring complete WWDC 2025 session transcripts covering:

- 🎤 **SpeechAnalyzer & SpeechTranscriber** API implementation guides
- 🤖 **Foundation Models** framework integration
- ✏️ **Rich Text Editor** advanced capabilities  
- 🔊 **Audio processing** improvements and optimizations

## 💬 Support & Community

**Get help and contribute:**

- 🐛 **Report issues** on GitHub Issues
- 📖 **Read documentation** in the `Docs/` directory
- 💡 **Feature requests** and enhancement suggestions
- 🤝 **Community contributions** welcome

---

**⭐ Star this repo** if you find it useful! | **🔗 Share** with developers interested in AI-powered speech transcription

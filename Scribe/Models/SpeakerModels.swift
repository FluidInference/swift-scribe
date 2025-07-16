import Foundation
import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Speaker Model

@Model
class Speaker {
    var id: String
    var name: String
    var colorRed: Double
    var colorGreen: Double
    var colorBlue: Double
    var createdAt: Date
    var embedding: [Float]?
    
    // Computed property for SwiftUI Color
    var displayColor: Color {
        get {
            return Color(red: colorRed, green: colorGreen, blue: colorBlue)
        }
        set {
            // Convert SwiftUI Color to RGB components using platform-specific methods
            #if os(iOS)
            let uiColor = UIColor(newValue)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            colorRed = Double(red)
            colorGreen = Double(green)
            colorBlue = Double(blue)
            #else
            let nsColor = NSColor(newValue)
            let rgbColor = nsColor.usingColorSpace(.sRGB) ?? NSColor.blue
            colorRed = Double(rgbColor.redComponent)
            colorGreen = Double(rgbColor.greenComponent)
            colorBlue = Double(rgbColor.blueComponent)
            #endif
        }
    }
    
    init(id: String = UUID().uuidString, name: String, displayColor: Color = .blue, embedding: [Float]? = nil) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.embedding = embedding
        
        // Initialize color components using platform-specific methods
        #if os(iOS)
        let uiColor = UIColor(displayColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.colorRed = Double(red)
        self.colorGreen = Double(green)
        self.colorBlue = Double(blue)
        #else
        let nsColor = NSColor(displayColor)
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? NSColor.blue
        self.colorRed = Double(rgbColor.redComponent)
        self.colorGreen = Double(rgbColor.greenComponent)
        self.colorBlue = Double(rgbColor.blueComponent)
        #endif
    }
    
    // Generate a unique color for a new speaker
    static func generateSpeakerColor(for speakerIndex: Int) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo, .brown
        ]
        return colors[speakerIndex % colors.count]
    }
}

// MARK: - Speaker Segment Model

@Model
class SpeakerSegment {
    var id: String
    var speakerId: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var text: String
    var confidence: Float
    var embedding: [Float]?
    
    // Relationship to the memo this segment belongs to
    var memo: Memo?
    
    var duration: TimeInterval {
        endTime - startTime
    }
    
    init(
        id: String = UUID().uuidString,
        speakerId: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        text: String = "",
        confidence: Float = 0.0,
        embedding: [Float]? = nil
    ) {
        self.id = id
        self.speakerId = speakerId
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.confidence = confidence
        self.embedding = embedding
    }
}

// MARK: - Diarization Result
// Note: Using FluidAudio.DiarizationResult and FluidAudio.TimedSpeakerSegment directly

// MARK: - Diarization Configuration

struct DiarizationConfig {
    var isEnabled: Bool = true
    var clusteringThreshold: Float = 0.7
    var minSegmentDuration: TimeInterval = 0.5
    var maxSpeakers: Int? = nil
    var enableRealTimeProcessing: Bool = false
    
    static let `default` = DiarizationConfig()
}

// MARK: - Speaker Attribution Extension

extension AttributedString {
    static let speakerIDKey = AttributeScopes.FoundationAttributes.SpeakerIDAttribute.self
    static let speakerConfidenceKey = AttributeScopes.FoundationAttributes.SpeakerConfidenceAttribute.self
}

extension AttributeScopes.FoundationAttributes {
    enum SpeakerIDAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = String
        static let name = "speakerID"
    }
    
    enum SpeakerConfidenceAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = Float
        static let name = "speakerConfidence"
    }
}

// MARK: - Speaker Management Extensions

extension Speaker {
    static func findOrCreate(withId id: String, in context: ModelContext) -> Speaker {
        let descriptor = FetchDescriptor<Speaker>(predicate: #Predicate { $0.id == id })
        
        if let existingSpeaker = try? context.fetch(descriptor).first {
            return existingSpeaker
        }
        
        // Create new speaker with generated name and color
        let speakerCount = (try? context.fetch(FetchDescriptor<Speaker>()).count) ?? 0
        let newSpeaker = Speaker(
            id: id,
            name: "Speaker \(speakerCount + 1)",
            displayColor: Speaker.generateSpeakerColor(for: speakerCount)
        )
        
        context.insert(newSpeaker)
        return newSpeaker
    }
}
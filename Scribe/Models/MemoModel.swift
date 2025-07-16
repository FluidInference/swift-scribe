import AVFoundation
import Foundation
import FoundationModels
import FluidAudio
import SwiftData
import SwiftUI

@Model
class Memo {
    typealias StartTime = CMTime

    var title: String
    var text: AttributedString
    var url: URL?  // Audio file URL
    var isDone: Bool
    var createdAt: Date
    var duration: TimeInterval?

    // AI-enhanced content - now using AttributedString for rich formatting
    var summary: AttributedString?

    // Speaker diarization data
    var hasSpeakerData: Bool = false
    var speakerSegments: [SpeakerSegment] = []

    // This can't be persisted with SwiftData since DiarizationResult isn't a @Model
    @Transient var diarizationResult: DiarizationResult?

    init(
        title: String, text: AttributedString, url: URL? = nil, isDone: Bool = false,
        duration: TimeInterval? = nil
    ) {
        self.title = title
        self.text = text
        self.url = url
        self.isDone = isDone
        self.duration = duration
        self.createdAt = Date()
        self.summary = nil
        self.hasSpeakerData = false
        self.speakerSegments = []
        self.diarizationResult = nil
    }

    /// Generates an AI-enhanced title and summary, storing them persistently
    func generateAIEnhancements() async throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw FoundationModelsError.generationFailed(
                NSError(domain: "Foundation Models not available", code: -1))
        }

        let transcriptText = String(text.characters)
        guard !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationModelsError.generationFailed(
                NSError(domain: "No content to enhance", code: -2))
        }

        // Generate enhanced title and summary concurrently
        let titleResult = try? await generateEnhancedTitle(from: transcriptText)
        let summaryResult = try? await generateRichSummary(from: transcriptText)

        // Update the memo with generated content
        self.title = titleResult ?? "New Note"
        self.summary = summaryResult ?? "Something went wrong generating a summary."
    }

    private func generateEnhancedTitle(from text: String) async throws -> String {
        let session = FoundationModelsHelper.createSession(
            instructions: """
                You are an expert at creating clear, descriptive titles for voice memos and transcripts.
                Your task is to create a concise, informative title that captures the main topic or purpose.

                Guidelines:
                - Keep titles between 3-8 words
                - Use title case (capitalize major words)
                - Focus on the main topic or key insight
                - Avoid generic words like memo or recording
                - Be specific and descriptive
                - Do not wrap the title in quotes
                """)

        let prompt =
            "Create a clear, descriptive title for this voice memo transcript (do not include quotes in your response):\n\n\(text)"

        let title = try await FoundationModelsHelper.generateText(
            session: session,
            prompt: prompt,
            options: FoundationModelsHelper.temperatureOptions(0.3)  // Low temperature for consistent titles
        )
        return title.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
            of: "\"", with: "")
    }

    private func generateRichSummary(from text: String) async throws -> AttributedString {
        let session = FoundationModelsHelper.createSession(
            instructions: """
                You are an expert at creating concise, informative summaries of voice memos and transcripts.
                Your summaries should capture the key points, main topics, and important details.

                Guidelines:
                - Create 2-4 well-structured paragraphs
                - Include key points and important details
                - Mark important concepts or key terms that should be highlighted
                - Output in markdown format
                """)

        let prompt = "Create a comprehensive summary of this voice memo transcript:\n\n\(text)"
        let summaryText = try await FoundationModelsHelper.generateText(
            session: session,
            prompt: prompt,
            options: FoundationModelsHelper.temperatureOptions(0.4)
        )

        // Convert to AttributedString
        return try AttributedString(markdown: summaryText)
    }

    // Legacy method for backward compatibility
    func suggestedTitle() async throws -> String? {
        return try await generateEnhancedTitle(from: String(text.characters))
    }

    // Legacy method for backward compatibility - now returns AttributedString
    func summarize(using template: String) async throws -> AttributedString? {
        return try await generateRichSummary(from: String(text.characters))
    }
}

extension Memo {
    static func blank() -> Memo {
        return .init(title: "New Memo", text: AttributedString(""))
    }

    // MARK: - Speaker Diarization Methods

        /// Updates the memo with diarization results
    func updateWithDiarizationResult(_ result: DiarizationResult, in context: ModelContext) {
        self.diarizationResult = result
        self.hasSpeakerData = !result.segments.isEmpty

        // Clear existing segments
        self.speakerSegments.removeAll()

        // Create speaker segments and ensure speakers exist in database
        for segment in result.segments {
            let speakerSegment = SpeakerSegment(
                speakerId: segment.speakerId,
                startTime: TimeInterval(segment.startTimeSeconds),
                endTime: TimeInterval(segment.endTimeSeconds),
                confidence: segment.qualityScore,
                embedding: segment.embedding
            )
            speakerSegment.memo = self
            self.speakerSegments.append(speakerSegment)
            context.insert(speakerSegment)

            // Ensure speaker exists in database
            let speaker = Speaker.findOrCreate(withId: segment.speakerId, in: context)
            speaker.embedding = segment.embedding
        }
    }

    /// Returns an attributed string with speaker information embedded
    func textWithSpeakerAttributes(context: ModelContext) -> AttributedString {
        guard hasSpeakerData else { return text }

        var attributedText = AttributedString(String(text.characters))

                // Apply speaker attributes to segments
        for segment in speakerSegments.sorted(by: { $0.startTime < $1.startTime }) {
            // Find the corresponding speaker
            let speakerId = segment.speakerId
            let descriptor = FetchDescriptor<Speaker>(predicate: #Predicate { speaker in
                speaker.id == speakerId
            })
            if let speaker = try? context.fetch(descriptor).first {

                // Estimate character positions based on timing (rough approximation)
                let totalDuration = duration ?? 1.0
                let totalLength = attributedText.characters.count

                let startPosition = max(0, Int((segment.startTime / totalDuration) * Double(totalLength)))
                let endPosition = min(totalLength, Int((segment.endTime / totalDuration) * Double(totalLength)))

                if startPosition < endPosition {
                    let range = attributedText.characters.index(attributedText.startIndex, offsetBy: startPosition)..<attributedText.characters.index(attributedText.startIndex, offsetBy: endPosition)

                    attributedText[range].foregroundColor = speaker.displayColor
                    attributedText[range][AttributedString.speakerIDKey] = speaker.id
                    attributedText[range][AttributedString.speakerConfidenceKey] = segment.confidence
                }
            }
        }

        return attributedText
    }

        /// Returns speakers present in this memo
    func speakers(in context: ModelContext) -> [Speaker] {
        guard hasSpeakerData else { return [] }

        let speakerIds = Set(speakerSegments.map { $0.speakerId })
        let descriptor = FetchDescriptor<Speaker>(predicate: #Predicate { speaker in
            speakerIds.contains(speaker.id)
        })

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Returns a formatted transcript with speaker labels
    func formattedTranscriptWithSpeakers(context: ModelContext) -> AttributedString {
        guard hasSpeakerData else { return textBrokenUpByParagraphs() }

        var result = AttributedString("")
        let sortedSegments = speakerSegments.sorted(by: { $0.startTime < $1.startTime })

                for (index, segment) in sortedSegments.enumerated() {
            // Get speaker information
            let speakerId = segment.speakerId
            let descriptor = FetchDescriptor<Speaker>(predicate: #Predicate { speaker in
                speaker.id == speakerId
            })
            let speaker = try? context.fetch(descriptor).first
            let speakerName = speaker?.name ?? "Speaker \(segment.speakerId)"

            // Add speaker label
            var speakerLabel = AttributedString("\(speakerName): ")
            speakerLabel.font = .headline
            speakerLabel.foregroundColor = speaker?.displayColor ?? .primary

            result.append(speakerLabel)

            // Add segment text
            var segmentText = AttributedString(segment.text)
            segmentText.foregroundColor = .primary
            result.append(segmentText)

            // Add line break between segments
            if index < sortedSegments.count - 1 {
                result.append(AttributedString("\n\n"))
            }
        }

        return result
    }

    func textBrokenUpByParagraphs() -> AttributedString {
        print(String(text.characters))
        if url == nil {
            print("url was nil")
            return text
        } else {
            var final = AttributedString("")
            var working = AttributedString("")
            let copy = text
            copy.runs.forEach { run in
                if copy[run.range].characters.contains(".") {
                    working.append(copy[run.range])
                    final.append(working)
                    final.append(AttributedString("\n\n"))
                    working = AttributedString("")
                } else {
                    if working.characters.isEmpty {
                        let newText = copy[run.range].characters
                        let attributes = run.attributes
                        let trimmed = newText.trimmingPrefix(" ")
                        let newAttributed = AttributedString(trimmed, attributes: attributes)
                        working.append(newAttributed)
                    } else {
                        working.append(copy[run.range])
                    }
                }
            }

            if final.characters.isEmpty {
                return working
            }

            return final
        }
    }
}

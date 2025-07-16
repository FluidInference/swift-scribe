import SwiftUI
import FluidAudio

@Observable
class AppSettings {
    var colorScheme: ColorScheme?
    
    // Diarization settings
    var diarizationEnabled: Bool = true
    var clusteringThreshold: Float = 0.7
    var minSegmentDuration: TimeInterval = 0.5
    var maxSpeakers: Int? = nil
    var enableRealTimeProcessing: Bool = false

    init() {
        // Load saved settings
        if let savedScheme = UserDefaults.standard.object(forKey: "colorScheme") as? Int {
            switch savedScheme {
            case 0:
                self.colorScheme = .light
            case 1:
                self.colorScheme = .dark
            default:
                self.colorScheme = nil
            }
        } else {
            self.colorScheme = nil
        }
        
        // Load diarization settings
        loadDiarizationSettings()
    }

    func setColorScheme(_ scheme: ColorScheme?) {
        self.colorScheme = scheme

        // Save to UserDefaults
        if let scheme = scheme {
            UserDefaults.standard.set(scheme == .light ? 0 : 1, forKey: "colorScheme")
        } else {
            UserDefaults.standard.removeObject(forKey: "colorScheme")
        }
    }

    var themeDisplayName: String {
        switch colorScheme {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case nil:
            return "System"
        case .some(_):
            return "System"
        }
    }
    
    // MARK: - Diarization Settings
    
    private func loadDiarizationSettings() {
        diarizationEnabled = UserDefaults.standard.object(forKey: "diarizationEnabled") as? Bool ?? true
        clusteringThreshold = UserDefaults.standard.object(forKey: "clusteringThreshold") as? Float ?? 0.7
        minSegmentDuration = UserDefaults.standard.object(forKey: "minSegmentDuration") as? TimeInterval ?? 0.5
        maxSpeakers = UserDefaults.standard.object(forKey: "maxSpeakers") as? Int
        enableRealTimeProcessing = UserDefaults.standard.object(forKey: "enableRealTimeProcessing") as? Bool ?? false
    }
    
    func setDiarizationEnabled(_ enabled: Bool) {
        self.diarizationEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "diarizationEnabled")
    }
    
    func setClusteringThreshold(_ threshold: Float) {
        self.clusteringThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: "clusteringThreshold")
    }
    
    func setMinSegmentDuration(_ duration: TimeInterval) {
        self.minSegmentDuration = duration
        UserDefaults.standard.set(duration, forKey: "minSegmentDuration")
    }
    
    func setMaxSpeakers(_ speakers: Int?) {
        self.maxSpeakers = speakers
        if let speakers = speakers {
            UserDefaults.standard.set(speakers, forKey: "maxSpeakers")
        } else {
            UserDefaults.standard.removeObject(forKey: "maxSpeakers")
        }
    }
    
    func setEnableRealTimeProcessing(_ enabled: Bool) {
        self.enableRealTimeProcessing = enabled
        UserDefaults.standard.set(enabled, forKey: "enableRealTimeProcessing")
    }
    
    /// Returns the current diarization configuration for FluidAudio
    func diarizationConfig() -> DiarizerConfig {
        return DiarizerConfig(
            clusteringThreshold: clusteringThreshold,
            minDurationOn: Float(minSegmentDuration),
            minDurationOff: 0.5, // Default value from FluidAudio
            numClusters: maxSpeakers ?? -1, // -1 for auto-detect
            minActivityThreshold: 10.0, // Default value from FluidAudio
            debugMode: false,
            modelCacheDirectory: nil
        )
    }
}

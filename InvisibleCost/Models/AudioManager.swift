import Foundation
import AVFoundation
import Observation

/// Manages spatial audio for the narrative experience
/// Handles: Voiceover narration, ambient soundscapes, phase-specific audio cues
@Observable
class AudioManager {
    private var audioEngine: AVAudioEngine?
    private var narrationPlayer: AVAudioPlayerNode?
    private var ambientPlayer: AVAudioPlayerNode?
    private var environmentNode: AVAudioEnvironmentNode?
    
    var isPlaying: Bool = false
    var currentNarrationPhase: NarrativePhase = .waiting
    
    // Narration cues per phase (timecodes from spec)
    private let narrationCues: [NarrativePhase: String] = [
        .spatialOverwhelm: "narration_overwhelm",    // "Every organization carries a hidden cost..."
        .realityCrack: "narration_crack",            // "Invisible work is costing more..."
        .humanFragment: "narration_fragment",        // "You made 247 decisions today..."
        .dataChoreography: "narration_choreography", // "What if this work..."
        .humanRestoration: "narration_restoration",  // Minimal - visual focus
        .exitMoment: "narration_exit"                // "Agentic automation returns..."
    ]
    
    // Ambient sounds per phase
    private let ambientSounds: [NarrativePhase: String] = [
        .spatialOverwhelm: "ambient_chaos",
        .realityCrack: "ambient_silence",
        .humanFragment: "ambient_tension",
        .dataChoreography: "ambient_assembly",
        .humanRestoration: "ambient_warmth",
        .exitMoment: "ambient_resolution"
    ]
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { return }
        
        // Create players
        narrationPlayer = AVAudioPlayerNode()
        ambientPlayer = AVAudioPlayerNode()
        environmentNode = AVAudioEnvironmentNode()
        
        guard let narration = narrationPlayer,
              let ambient = ambientPlayer,
              let environment = environmentNode else { return }
        
        // Attach nodes
        engine.attach(narration)
        engine.attach(ambient)
        engine.attach(environment)
        
        // Connect: players → environment → output
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(narration, to: environment, format: format)
        engine.connect(ambient, to: environment, format: format)
        engine.connect(environment, to: engine.mainMixerNode, format: format)
        
        // Configure spatial audio
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environment.renderingAlgorithm = .sphericalHead
        
        do {
            try engine.start()
        } catch {
            print("AudioManager: Failed to start engine - \(error)")
        }
    }
    
    // MARK: - Playback Control
    
    func playNarrationForPhase(_ phase: NarrativePhase) {
        currentNarrationPhase = phase
        
        guard let cueFile = narrationCues[phase] else { return }
        playAudioFile(cueFile, on: narrationPlayer, position: AVAudio3DPoint(x: 0, y: 1.5, z: -1))
        
        if let ambientFile = ambientSounds[phase] {
            playAudioFile(ambientFile, on: ambientPlayer, position: AVAudio3DPoint(x: 0, y: 0, z: 0))
        }
        
        isPlaying = true
    }
    
    func stopAllAudio() {
        narrationPlayer?.stop()
        ambientPlayer?.stop()
        isPlaying = false
    }
    
    func fadeOut(duration: TimeInterval = 1.0) {
        // Gradual volume reduction
        guard let engine = audioEngine else { return }
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = engine.mainMixerNode.outputVolume / Float(steps)
        
        Task {
            for _ in 0..<steps {
                engine.mainMixerNode.outputVolume -= volumeStep
                try? await Task.sleep(for: .seconds(stepDuration))
            }
            stopAllAudio()
            engine.mainMixerNode.outputVolume = 1.0
        }
    }
    
    private func playAudioFile(_ filename: String, on player: AVAudioPlayerNode?, position: AVAudio3DPoint) {
        guard let player = player,
              let url = Bundle.main.url(forResource: filename, withExtension: "m4a"),
              let file = try? AVAudioFile(forReading: url) else {
            // Audio file not found - this is expected during development
            print("AudioManager: Audio file '\(filename)' not found - continuing without audio")
            return
        }
        
        player.stop()
        player.scheduleFile(file, at: nil)
        player.position = position
        player.play()
    }
    
    // MARK: - Spatial Positioning
    
    func updateListenerPosition(x: Float, y: Float, z: Float) {
        environmentNode?.listenerPosition = AVAudio3DPoint(x: x, y: y, z: z)
    }
    
    func updateListenerOrientation(forward: AVAudio3DVector, up: AVAudio3DVector) {
        environmentNode?.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: forward, up: up)
    }
}








import Foundation
import AVFoundation
import AudioToolbox

/// Comprehensive audio manager for the Invisible Cost iPad experience
/// Handles narration, ambient sounds, and transition effects
@Observable
class AudioManager {
    static let shared = AudioManager()
    
    // Audio engine
    private var audioEngine: AVAudioEngine!
    private var ambientPlayerNode: AVAudioPlayerNode!
    private var effectPlayerNode: AVAudioPlayerNode!
    private var mixerNode: AVAudioMixerNode!
    
    // Speech synthesizer for narration
    private let synthesizer = AVSpeechSynthesizer()
    
    // State
    private(set) var isAmbientPlaying = false
    private(set) var isNarrationPlaying = false
    
    // Volume controls
    var ambientVolume: Float = 0.12
    var narrationVolume: Float = 1.0
    var effectsVolume: Float = 0.35
    
    // Audio format
    private var audioFormat: AVAudioFormat!
    
    private init() {
        setupAudioSession()
        setupAudioEngine()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        ambientPlayerNode = AVAudioPlayerNode()
        effectPlayerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()
        
        audioEngine.attach(ambientPlayerNode)
        audioEngine.attach(effectPlayerNode)
        audioEngine.attach(mixerNode)
        
        // Standard format for generated audio
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        // Connect nodes
        audioEngine.connect(ambientPlayerNode, to: mixerNode, format: audioFormat)
        audioEngine.connect(effectPlayerNode, to: mixerNode, format: audioFormat)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        
        do {
            try audioEngine.start()
            print("🔊 Audio engine started successfully")
        } catch {
            print("⚠️ Audio engine start failed: \(error)")
        }
    }
    
    // MARK: - Ambient Sounds
    
    /// Play ambient office/work environment sounds
    func playAmbientHum() {
        guard !isAmbientPlaying else { return }
        
        isAmbientPlaying = true
        ambientPlayerNode.volume = ambientVolume
        
        // Generate ambient buffer
        let buffer = generateAmbientBuffer(duration: 10.0)
        
        // Loop the ambient sound
        ambientPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops) { [weak self] in
            // This is called when buffer completes (won't be called with loops)
        }
        
        ambientPlayerNode.play()
        print("🔊 Ambient hum started")
    }
    
    private func generateAmbientBuffer(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        // Generate layered ambient sound
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // Low frequency drone (60Hz with slow modulation)
            let modulation = sin(t * 0.3) * 3.0
            let drone = sin(2.0 * .pi * (60.0 + modulation) * t) * 0.15
            
            // Higher harmonic (120Hz)
            let harmonic1 = sin(2.0 * .pi * 120.0 * t) * 0.05
            
            // Very subtle noise
            let noise = (Double.random(in: -1...1)) * 0.02
            
            // Subtle pulsing envelope
            let pulse = 0.8 + 0.2 * sin(t * 0.5)
            
            let sample = Float((drone + harmonic1 + noise) * pulse)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    /// Fade out and stop ambient sounds
    func fadeOutAmbient(duration: TimeInterval = 2.0) {
        guard isAmbientPlaying else { return }
        
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let originalVolume = ambientVolume
        let volumeStep = originalVolume / Float(fadeSteps)
        
        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                self?.ambientPlayerNode.volume = originalVolume - volumeStep * Float(i + 1)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopAmbient()
            self?.ambientPlayerNode.volume = originalVolume
        }
    }
    
    func stopAmbient() {
        ambientPlayerNode.stop()
        isAmbientPlaying = false
    }
    
    // MARK: - Narration
    
    /// Narrator lines for each phase
    private let narratorLines: [String: String] = [
        "opening_1": "Every organization carries a hidden cost.",
        "opening_2": "Most leaders never see it.",
        "opening_3": "You made 247 decisions today. 142 were unnecessary.",
        "vignette_finance": "In Finance, reconciliation fatigue consumes hours of skilled attention.",
        "vignette_supply": "Supply chain teams drown in manual tracking overhead.",
        "vignette_health": "Healthcare professionals spend more time on paperwork than patients.",
        "pattern_break": "What if this work... wasn't your work?",
        "agentic": "Agentic orchestration. Intelligence that works while you think.",
        "human_return": "Human potential returned. Reviewing insights. Approving paths.",
        "restoration": "Restoration.",
        "closing": "Agentic automation returns invisible work to the people who matter.",
        "question": "What could your organization become?"
    ]
    
    /// Play narration for a specific phase using text-to-speech
    func playNarration(for key: String, completion: (() -> Void)? = nil) {
        guard let text = narratorLines[key] else {
            print("⚠️ No narration found for key: \(key)")
            completion?()
            return
        }
        
        speakNarration(text, completion: completion)
    }
    
    private func speakNarration(_ text: String, completion: (() -> Void)?) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        utterance.rate = 0.48
        utterance.pitchMultiplier = 0.92
        utterance.volume = narrationVolume
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.3
        
        isNarrationPlaying = true
        print("🎙️ Narrating: \"\(text)\"")
        
        synthesizer.speak(utterance)
        
        let wordCount = text.components(separatedBy: " ").count
        let estimatedDuration = Double(wordCount) * 0.45 + 0.8
        
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) { [weak self] in
            self?.isNarrationPlaying = false
            completion?()
        }
    }
    
    func stopNarration() {
        synthesizer.stopSpeaking(at: .immediate)
        isNarrationPlaying = false
    }
    
    // MARK: - Sound Effects
    
    /// Play transition/whoosh sound
    func playTransition() {
        let buffer = generateTransitionBuffer()
        playEffect(buffer: buffer, name: "Transition")
    }
    
    /// Play subtle UI feedback sound
    func playUIFeedback() {
        // Use system haptic sound for UI feedback (more reliable)
        AudioServicesPlaySystemSound(1104) // Subtle tick
        print("🔔 UI feedback (system)")
    }
    
    /// Play reveal/appearance sound
    func playReveal() {
        let buffer = generateRevealBuffer()
        playEffect(buffer: buffer, name: "Reveal")
    }
    
    /// Play completion/success sound
    func playCompletion() {
        let buffer = generateCompletionBuffer()
        playEffect(buffer: buffer, name: "Completion")
    }
    
    /// Play sphere formation sound (building up)
    func playSphereForming() {
        let buffer = generateSphereFormingBuffer()
        playEffect(buffer: buffer, name: "Sphere forming")
    }
    
    /// Play connection sound (quick blip)
    func playConnection() {
        let buffer = generateConnectionBuffer()
        playEffect(buffer: buffer, name: "Connection")
    }
    
    /// Play dot appearing sound (soft crystalline ping)
    func playDotAppear() {
        let buffer = generateDotAppearBuffer()
        playEffect(buffer: buffer, name: "Dot appear")
    }
    
    /// Play line forming sound (stretchy connection)
    func playLineForming() {
        let buffer = generateLineFormingBuffer()
        playEffect(buffer: buffer, name: "Line forming")
    }
    
    /// Play sphere pulse sound (resonant breath)
    func playSpherePulse() {
        let buffer = generateSpherePulseBuffer()
        playEffect(buffer: buffer, name: "Sphere pulse")
    }
    
    /// Play sphere shrink sound (compression descent)
    func playSphereShrink() {
        let buffer = generateSphereShrinkBuffer()
        playEffect(buffer: buffer, name: "Sphere shrink")
    }
    
    private func playEffect(buffer: AVAudioPCMBuffer, name: String) {
        effectPlayerNode.stop()
        effectPlayerNode.volume = effectsVolume
        effectPlayerNode.scheduleBuffer(buffer, at: nil, options: []) { }
        effectPlayerNode.play()
        print("🔔 \(name) sound")
    }
    
    // MARK: - Sound Generation
    
    private func generateTransitionBuffer() -> AVAudioPCMBuffer {
        let duration = 0.4
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Descending frequency sweep
            let freq = 800.0 - 600.0 * progress
            
            // Envelope
            let attack = min(t / 0.05, 1.0)
            let decay = max(0, 1.0 - (t - 0.05) / 0.35)
            let envelope = attack * decay
            
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope * 0.6)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateRevealBuffer() -> AVAudioPCMBuffer {
        let duration = 0.8
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Ascending frequency sweep (magical reveal)
            let freq = 200.0 + 600.0 * progress
            
            // Softer envelope with longer sustain
            let attack = min(t / 0.3, 1.0)
            let decay = max(0, 1.0 - max(0, (t - 0.3)) / 0.5)
            let envelope = attack * decay
            
            // Add harmonics for richness
            let fundamental = sin(2.0 * .pi * freq * t) * 0.5
            let harmonic = sin(2.0 * .pi * freq * 2.0 * t) * 0.2
            
            let sample = Float((fundamental + harmonic) * envelope)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateCompletionBuffer() -> AVAudioPCMBuffer {
        let duration = 0.6
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Two-tone success sound
            let freq1 = 400.0
            let freq2 = 600.0
            
            // Switch between tones
            let freq = progress < 0.5 ? freq1 : freq2
            
            // Envelope for each tone
            let toneProgress = progress < 0.5 ? progress * 2 : (progress - 0.5) * 2
            let attack = min(toneProgress / 0.1, 1.0)
            let decay = max(0, 1.0 - max(0, toneProgress - 0.1) / 0.9)
            let envelope = attack * decay
            
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope * 0.5)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateSphereFormingBuffer() -> AVAudioPCMBuffer {
        let duration = 1.5
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Building up frequency and intensity
            let freq = 80.0 + 400.0 * progress * progress // Accelerating rise
            
            // Gradual build envelope
            let envelope = progress * 0.8
            
            // Multiple harmonics for richness
            let fundamental = sin(2.0 * .pi * freq * t) * 0.4
            let harmonic1 = sin(2.0 * .pi * freq * 1.5 * t) * 0.2
            let harmonic2 = sin(2.0 * .pi * freq * 2.0 * t) * 0.1
            
            // Add subtle pulse
            let pulse = 1.0 + 0.1 * sin(t * 8.0)
            
            let sample = Float((fundamental + harmonic1 + harmonic2) * envelope * pulse)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateConnectionBuffer() -> AVAudioPCMBuffer {
        let duration = 0.15
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Quick ascending blip
            let freq = 600.0 + 400.0 * progress
            
            // Sharp envelope
            let attack = min(t / 0.03, 1.0)
            let decay = max(0, 1.0 - max(0, t - 0.03) / 0.12)
            let envelope = attack * decay
            
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope * 0.4)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateDotAppearBuffer() -> AVAudioPCMBuffer {
        let duration = 0.12
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Crystalline ping - high frequency with slight wobble
            let baseFreq = 1200.0
            let wobble = sin(t * 40.0) * 50.0
            let freq = baseFreq + wobble - 200.0 * progress
            
            // Sharp attack, bell-like decay
            let attack = min(t / 0.01, 1.0)
            let decay = exp(-t * 25.0)
            let envelope = attack * decay
            
            // Add sparkle with harmonics
            let fundamental = sin(2.0 * .pi * freq * t) * 0.4
            let harmonic = sin(2.0 * .pi * freq * 2.5 * t) * 0.15 * decay
            
            let sample = Float((fundamental + harmonic) * envelope)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateLineFormingBuffer() -> AVAudioPCMBuffer {
        let duration = 0.25
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Stretching/zipping sound - frequency glide
            let freq = 300.0 + 500.0 * progress * progress
            
            // Soft envelope with sustain
            let attack = min(t / 0.05, 1.0)
            let sustain = 1.0 - progress * 0.3
            let decay = max(0, 1.0 - max(0, t - 0.15) / 0.1)
            let envelope = attack * sustain * decay
            
            // Dual oscillator for thickness
            let osc1 = sin(2.0 * .pi * freq * t)
            let osc2 = sin(2.0 * .pi * (freq * 1.02) * t) // Slight detune
            
            let sample = Float((osc1 * 0.3 + osc2 * 0.2) * envelope)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateSpherePulseBuffer() -> AVAudioPCMBuffer {
        let duration = 0.5
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Deep resonant pulse - breathing sound
            let baseFreq = 120.0
            let freq = baseFreq + 30.0 * sin(t * 6.0) // Subtle frequency modulation
            
            // Breath-like envelope (in and out)
            let breathCurve = sin(.pi * progress)
            let envelope = breathCurve * 0.6
            
            // Rich harmonics for depth
            let fundamental = sin(2.0 * .pi * freq * t) * 0.4
            let harmonic1 = sin(2.0 * .pi * freq * 2.0 * t) * 0.2
            let harmonic2 = sin(2.0 * .pi * freq * 3.0 * t) * 0.1
            let subHarmonic = sin(2.0 * .pi * freq * 0.5 * t) * 0.15
            
            let sample = Float((fundamental + harmonic1 + harmonic2 + subHarmonic) * envelope)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateSphereShrinkBuffer() -> AVAudioPCMBuffer {
        let duration = 0.8
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Compression descent - frequency drops, gets denser
            let startFreq = 600.0
            let endFreq = 150.0
            let freq = startFreq - (startFreq - endFreq) * progress * progress
            
            // Compress envelope - gets tighter
            let attack = min(t / 0.1, 1.0)
            let sustain = 1.0 - progress * 0.5
            let tail = max(0, 1.0 - max(0, t - 0.5) / 0.3)
            let envelope = attack * sustain * tail
            
            // Layered oscillators with increasing density
            let osc1 = sin(2.0 * .pi * freq * t)
            let osc2 = sin(2.0 * .pi * freq * 1.5 * t) * (0.5 + progress * 0.5)
            let osc3 = sin(2.0 * .pi * freq * 2.0 * t) * progress * 0.3
            
            // Add subtle vibrato for tension
            let vibrato = 1.0 + 0.05 * sin(t * 30.0 * (1 + progress))
            
            let sample = Float((osc1 * 0.35 + osc2 * 0.15 + osc3 * 0.1) * envelope * vibrato)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    // MARK: - Phase-based Audio Control
    
    func playAudioForPhase(_ phase: Tier1Phase) {
        switch phase {
        case .waiting, .complete:
            break
        case .microColdOpen:
            playAmbientHum()
        case .narratorFrame:
            // Handled by NarrativeView progress triggers
            break
        case .humanVignettes:
            playTransition()
        case .patternBreak:
            fadeOutAmbient(duration: 1.5)
        case .agenticOrchestration:
            playReveal()
        case .humanReturn:
            playReveal()
        case .personalization:
            playUIFeedback()
        case .stillnessCTA:
            playCompletion()
        }
    }
    
    // MARK: - Cleanup
    
    func stopAll() {
        stopAmbient()
        stopNarration()
        effectPlayerNode.stop()
    }
    
    deinit {
        audioEngine.stop()
    }
}

// MARK: - Tier1Phase Extension for Audio

extension Tier1Phase {
    var narratorKeys: [String] {
        switch self {
        case .waiting, .complete, .microColdOpen, .personalization:
            return []
        case .narratorFrame:
            return ["opening_1", "opening_2", "opening_3"]
        case .humanVignettes:
            return ["vignette_finance", "vignette_supply", "vignette_health"]
        case .patternBreak:
            return ["pattern_break"]
        case .agenticOrchestration:
            return ["agentic"]
        case .humanReturn:
            return ["restoration", "human_return"]
        case .stillnessCTA:
            return ["closing", "question"]
        }
    }
}

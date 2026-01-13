import Foundation
import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Enhanced Audio Manager
/// Comprehensive audio management for the enhanced Invisible Cost experience
/// Handles narration, ambient sounds, transition effects, and precise sync points

@Observable
class AudioManager {
    static let shared = AudioManager()

    // MARK: - Audio Engine
    private var audioEngine: AVAudioEngine!
    private var ambientPlayerNode: AVAudioPlayerNode!
    private var effectPlayerNode: AVAudioPlayerNode!
    private var mixerNode: AVAudioMixerNode!

    // MARK: - Players
    private var narrationPlayer: AVAudioPlayer?
    private var ambientMusicPlayer: AVAudioPlayer?
    private var upbeatMusicPlayer: AVAudioPlayer?
    private var effectPlayer: AVAudioPlayer?

    // MARK: - State
    private(set) var isAmbientPlaying = false
    private(set) var isNarrationPlaying = false
    private var isUpbeatMode = false
    private var currentNarrationKey: String?

    // MARK: - Volume Controls
    var ambientVolume: Float = 0.08
    var narrationVolume: Float = 1.0
    var effectsVolume: Float = 0.55

    // MARK: - Audio Format
    private var audioFormat: AVAudioFormat!

    // MARK: - Callbacks for sync
    var onNarrationComplete: (() -> Void)?

    // MARK: - Initialization

    private init() {
        setupAudioSession()
        setupAudioEngine()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[Audio] Session setup failed: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        ambientPlayerNode = AVAudioPlayerNode()
        effectPlayerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()

        audioEngine.attach(ambientPlayerNode)
        audioEngine.attach(effectPlayerNode)
        audioEngine.attach(mixerNode)

        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        audioEngine.connect(ambientPlayerNode, to: mixerNode, format: audioFormat)
        audioEngine.connect(effectPlayerNode, to: mixerNode, format: audioFormat)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: audioFormat)

        do {
            try audioEngine.start()
            print("[Audio] Engine started")
        } catch {
            print("[Audio] Engine start failed: \(error)")
        }
    }

    // MARK: - Narration Playback

    /// Enhanced narration scripts for all phases
    private let narratorLines: [String: String] = [
        // Industry Selection
        "choose_industry": "Choose your industry. See your invisible cost.",

        // Building Tension
        "building_finance": "Every report. Every reconciliation. Every manual entry that keeps your team from the work that matters.",
        "building_supply": "Every shipment tracked by hand. Every exception managed manually. Every delay cascading through your network.",
        "building_health": "Every chart note. Every referral fax. Every authorization that keeps healers from healing.",

        // Industry Vignettes (Enhanced)
        "vignette_finance_enhanced": "Hours lost to tasks that machines were made for.",
        "vignette_supply_enhanced": "Brilliant minds trapped in busywork.",
        "vignette_health_enhanced": "Healers buried under paperwork.",

        // Pattern Break
        "pattern_break_enhanced": "But what if... you could see the real number?",

        // Sucker Punch
        "sucker_punch_finance": "Forty-seven point five million dollars. Every. Single. Year. Gone. To invisible work.",
        "sucker_punch_supply": "Thirty-eight point two million dollars. Every. Single. Year. Evaporating. While you watch.",
        "sucker_punch_health": "Fifty-two point eight million dollars. Every. Single. Year. Stolen. From patient care.",

        // Comparisons - Finance
        "comparison_finance_1": "That's nine hundred fifty senior analyst salaries. Gone.",
        "comparison_finance_2": "Fifteen years of your entire IT budget. Vanished.",
        "comparison_finance_3": "A hundred eighty-nine thousand client meetings. Lost.",

        // Comparisons - Supply Chain
        "comparison_supply_1": "That's seven hundred sixty-four warehouse workers. Not hired.",
        "comparison_supply_2": "Twelve thousand seven hundred containers. Delayed.",
        "comparison_supply_3": "Your margins. Eroded. Daily.",

        // Comparisons - Healthcare
        "comparison_health_1": "That's over a thousand nurse salaries. Consumed by paperwork.",
        "comparison_health_2": "Twenty-six thousand patient visits. That didn't happen.",
        "comparison_health_3": "Your physicians' sanity. Under siege.",

        // Solution
        "agentic_enhanced": "This is Agentic Solutions. Intelligence that anticipates. Acts. And frees you to think.",
        "aa_reveal_enhanced": "From Automation Anywhere. Elevating Human Potential.",

        // Human Return
        "restoration_enhanced": "The chains dissolve. One by one.",
        "breathe": "And suddenly you remember what it feels like to breathe.",
        "purpose": "This is what happens when machines handle the mechanics and humans reclaim their purpose.",

        // Final CTA
        "final_cta_enhanced": "The invisible cost... ends now. The future of work... starts here.",
        "ready_change": "Ready to change this?"
    ]

    /// Play narration with completion callback for sync
    func playNarration(for key: String, completion: (() -> Void)? = nil) {
        currentNarrationKey = key

        // Try to find and play pre-recorded narration
        // Priority: 1) exact key match, 2) key with _enhanced suffix removed
        if playPreRecordedNarration(for: key, completion: completion) {
            return
        }

        // Fallback to TTS
        guard let text = narratorLines[key] else {
            print("[Audio] No narration found for key: \(key)")
            completion?()
            return
        }

        speakNarration(text, completion: completion)
    }

    private func playPreRecordedNarration(for key: String, completion: (() -> Void)?) -> Bool {
        let formats = ["mp3", "m4a", "wav", "aiff", "caf"]

        // Build list of filenames to try in priority order
        // 1. Exact match: narration_<key>
        // 2. If key ends with _enhanced, also try without the suffix
        var filenamesToTry = ["narration_\(key)"]
        if key.hasSuffix("_enhanced") {
            let baseKey = String(key.dropLast("_enhanced".count))
            filenamesToTry.append("narration_\(baseKey)")
        }

        for filename in filenamesToTry {
            for format in formats {
                if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                    do {
                        narrationPlayer?.stop()
                        narrationPlayer = try AVAudioPlayer(contentsOf: url)
                        narrationPlayer?.volume = narrationVolume
                        narrationPlayer?.prepareToPlay()

                        isNarrationPlaying = true
                        narrationPlayer?.play()

                        print("[Audio] Playing: \(filename).\(format)")

                        // Schedule completion
                        let duration = narrationPlayer?.duration ?? 2.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
                            self?.isNarrationPlaying = false
                            self?.currentNarrationKey = nil
                            completion?()
                        }

                        return true
                    } catch {
                        print("[Audio] Failed to play \(filename).\(format): \(error)")
                    }
                }
            }
        }

        print("[Audio] No audio file found for key: \(key)")
        return false
    }

    private func speakNarration(_ text: String, completion: (() -> Void)?) {
        let synthesizer = AVSpeechSynthesizer()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 0.95
        utterance.volume = narrationVolume

        isNarrationPlaying = true
        print("[Audio] TTS: \"\(text)\"")

        synthesizer.speak(utterance)

        let wordCount = text.components(separatedBy: " ").count
        let estimatedDuration = Double(wordCount) * 0.45 + 0.8

        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) { [weak self] in
            self?.isNarrationPlaying = false
            completion?()
        }
    }

    func stopNarration() {
        narrationPlayer?.stop()
        isNarrationPlaying = false
        currentNarrationKey = nil
    }

    // MARK: - Sound Effects

    /// Play selection confirmation sound
    func playSelectionSound() {
        playEffect("sfx_selection", fallback: self.generateSelectionBuffer(), name: "Selection")
        triggerHaptic(.medium)
    }

    /// Play sucker punch impact sound
    func playSuckerPunchImpact() {
        playEffect("sfx_impact_boom", fallback: self.generateImpactBuffer(), name: "Impact")
        triggerHaptic(.heavy)
    }

    /// Play counter tick sound (rapid during counting)
    func playCounterTick() {
        playEffect("sfx_counting_tick", fallback: self.generateTickBuffer(), name: "Tick")
    }

    /// Play card whoosh for comparison carousel
    func playCardWhoosh() {
        playEffect("sfx_card_whoosh", fallback: self.generateWhooshBuffer(), name: "Whoosh")
        triggerHaptic(.light)
    }

    /// Play transition sound
    func playTransition() {
        playEffect("sfx_transition", fallback: self.generateTransitionBuffer(), name: "Transition")
    }

    /// Play reveal sound
    func playReveal() {
        playEffect("sfx_reveal", fallback: self.generateRevealBuffer(), name: "Reveal")
    }

    /// Play completion chime
    func playCompletion() {
        playEffect("sfx_completion", fallback: self.generateCompletionBuffer(), name: "Completion")
    }

    /// Play UI feedback
    func playUIFeedback() {
        AudioServicesPlaySystemSound(1104)
    }

    /// Play tension tone (for pattern break)
    func playTensionTone() {
        playEffect("sfx_tension_tone", fallback: self.generateTensionBuffer(), name: "Tension")
    }

    /// Play ready chime (tap to continue indicator)
    func playReadyChime() {
        playEffect("sfx_ready_chime", fallback: self.generateReadyBuffer(), name: "Ready")
    }

    /// Play glow pulse sound (for sucker punch number pulse)
    func playGlowPulse() {
        playEffect("sfx_glow_pulse", fallback: self.generatePulseBuffer(), name: "Pulse")
    }

    private func playEffect(_ filename: String, fallback: @autoclosure () -> AVAudioPCMBuffer, name: String) {
        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                do {
                    effectPlayer?.stop()
                    effectPlayer = try AVAudioPlayer(contentsOf: url)
                    effectPlayer?.volume = effectsVolume
                    effectPlayer?.prepareToPlay()
                    effectPlayer?.play()
                    return
                } catch {
                    continue
                }
            }
        }

        // Fallback to synthesized
        let buffer = fallback()
        effectPlayerNode.stop()
        effectPlayerNode.volume = effectsVolume
        effectPlayerNode.scheduleBuffer(buffer, at: nil, options: []) { }
        effectPlayerNode.play()
    }

    // MARK: - Haptic Feedback

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // MARK: - Ambient Music

    func playAmbientMusic() {
        guard !isAmbientPlaying else { return }

        // Preload upbeat for later transition
        preloadUpbeatMusic()

        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: "ambient_music", withExtension: format) {
                do {
                    ambientMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientMusicPlayer?.numberOfLoops = -1  // Loop
                    ambientMusicPlayer?.volume = ambientVolume
                    ambientMusicPlayer?.prepareToPlay()
                    ambientMusicPlayer?.play()
                    isAmbientPlaying = true
                    print("[Audio] Ambient music started")
                    return
                } catch {
                    print("[Audio] Ambient music failed: \(error)")
                }
            }
        }

        // Fallback to synthesized ambient
        playGeneratedAmbient()
    }

    private func preloadUpbeatMusic() {
        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: "upbeat_music", withExtension: format) {
                do {
                    upbeatMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    upbeatMusicPlayer?.numberOfLoops = 0
                    upbeatMusicPlayer?.volume = 0
                    upbeatMusicPlayer?.prepareToPlay()
                    print("[Audio] Upbeat music preloaded")
                    return
                } catch { continue }
            }
        }
    }

    func transitionToUpbeatMusic(crossfadeDuration: TimeInterval = 1.5) {
        guard !isUpbeatMode, let upbeat = upbeatMusicPlayer else { return }

        isUpbeatMode = true
        let targetVolume: Float = 0.15

        upbeat.volume = 0
        upbeat.play()
        print("[Audio] Transitioning to upbeat")

        let steps = 15
        let stepDuration = crossfadeDuration / Double(steps)
        let ambientStep = ambientVolume / Float(steps)
        let upbeatStep = targetVolume / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                guard let self = self else { return }
                let newAmbient = max(0, self.ambientVolume - ambientStep * Float(i + 1))
                self.ambientMusicPlayer?.volume = newAmbient
                let newUpbeat = min(targetVolume, upbeatStep * Float(i + 1))
                self.upbeatMusicPlayer?.volume = newUpbeat
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + crossfadeDuration) { [weak self] in
            self?.ambientMusicPlayer?.stop()
            print("[Audio] Crossfade complete")
        }
    }

    func fadeOutMusic(duration: TimeInterval = 3.0) {
        let player = isUpbeatMode ? upbeatMusicPlayer : ambientMusicPlayer
        guard let currentPlayer = player else { return }

        let originalVolume = currentPlayer.volume
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = originalVolume / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                let newVolume = max(0, originalVolume - volumeStep * Float(i + 1))
                self?.ambientMusicPlayer?.volume = newVolume
                self?.upbeatMusicPlayer?.volume = newVolume
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopAllMusic()
        }
    }

    func stopAllMusic() {
        ambientMusicPlayer?.stop()
        upbeatMusicPlayer?.stop()
        ambientPlayerNode.stop()
        isAmbientPlaying = false
        isUpbeatMode = false
    }

    private func playGeneratedAmbient() {
        isAmbientPlaying = true
        ambientPlayerNode.volume = ambientVolume

        let buffer = generateAmbientBuffer(duration: 10.0)
        ambientPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops) { }
        ambientPlayerNode.play()
        print("[Audio] Synthesized ambient started")
    }

    // MARK: - Cleanup

    func stopAll() {
        stopAllMusic()
        stopNarration()
        effectPlayerNode.stop()
        effectPlayer?.stop()
    }

    deinit {
        audioEngine.stop()
    }

    // MARK: - Buffer Generation (Synthesized Fallbacks)

    private func generateAmbientBuffer(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let sub = sin(2.0 * .pi * 55.0 * t) * 0.06
            let pad = sin(2.0 * .pi * 110.0 * t) * 0.04
            let breath = 0.8 + 0.2 * sin(t * 0.15)
            let sample = Float((sub + pad) * breath)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateTransitionBuffer() -> AVAudioPCMBuffer {
        let duration = 0.35
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            let envelope = sin(progress * .pi) * 0.12
            let noise = Double.random(in: -1...1)
            let sample = Float(noise * envelope)
            left[frame] = sample * 0.9
            right[frame] = sample * 1.1
        }

        return buffer
    }

    private func generateSelectionBuffer() -> AVAudioPCMBuffer {
        let duration = 0.25
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let freq = 880.0 + 220.0 * (t / duration)
            let envelope = exp(-t * 8) * 0.3
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateImpactBuffer() -> AVAudioPCMBuffer {
        let duration = 1.0
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // Low impact thud
            let lowFreq = sin(2.0 * .pi * 60.0 * t) * exp(-t * 5) * 0.5
            // Mid punch
            let midFreq = sin(2.0 * .pi * 120.0 * t) * exp(-t * 8) * 0.3
            // High attack
            let highFreq = sin(2.0 * .pi * 400.0 * t) * exp(-t * 20) * 0.2

            let sample = Float(lowFreq + midFreq + highFreq)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateTickBuffer() -> AVAudioPCMBuffer {
        let duration = 0.03
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = exp(-t * 100) * 0.1
            let sample = Float(sin(2.0 * .pi * 2000.0 * t) * envelope)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateWhooshBuffer() -> AVAudioPCMBuffer {
        let duration = 0.3
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            let envelope = sin(progress * .pi) * 0.15
            let freq = 200.0 + 600.0 * progress
            let noise = Double.random(in: -1...1) * 0.5
            let tone = sin(2.0 * .pi * freq * t) * 0.5

            let sample = Float((noise + tone) * envelope)
            left[frame] = sample * Float(1.0 - progress)
            right[frame] = sample * Float(progress)
        }

        return buffer
    }

    private func generateRevealBuffer() -> AVAudioPCMBuffer {
        let duration = 0.8
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let freq = 392.0
            let attack = min(t / 0.1, 1.0)
            let decay = exp(-t * 2.5)
            let envelope = attack * decay * 0.15
            let tone = sin(2.0 * .pi * freq * t)
            let warmth = sin(2.0 * .pi * freq * 0.5 * t) * 0.3

            let sample = Float((tone + warmth) * envelope)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateCompletionBuffer() -> AVAudioPCMBuffer {
        let duration = 1.0
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let note1Env = exp(-t * 4) * 0.12
            let note2Env = max(0, t - 0.15) < 0.01 ? 0 : exp(-(t - 0.15) * 3) * 0.10

            let note1 = sin(2.0 * .pi * 392.0 * t) * note1Env
            let note2 = sin(2.0 * .pi * 523.25 * t) * note2Env

            let sample = Float(note1 + note2)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateTensionBuffer() -> AVAudioPCMBuffer {
        let duration = 2.0
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            // Deep drone that builds
            let freq = 55.0 + 20.0 * progress
            let envelope = (1.0 - progress) * 0.2
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generateReadyBuffer() -> AVAudioPCMBuffer {
        let duration = 0.5
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // Two-note chime
            let note1 = sin(2.0 * .pi * 880.0 * t) * exp(-t * 5)
            let note2 = (t > 0.15) ? sin(2.0 * .pi * 1320.0 * (t - 0.15)) * exp(-(t - 0.15) * 6) : 0

            let sample = Float((note1 + note2) * 0.1)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }

    private func generatePulseBuffer() -> AVAudioPCMBuffer {
        let duration = 0.6
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            let freq = 200.0 - 100.0 * progress
            let envelope = sin(progress * .pi) * 0.15

            let sample = Float(sin(2.0 * .pi * freq * t) * envelope)
            left[frame] = sample
            right[frame] = sample
        }

        return buffer
    }
}

// MARK: - Phase Audio Handling Extension

extension AudioManager {
    /// Play audio for a specific enhanced phase
    func playAudioForPhase(_ phase: Tier1Phase, industry: Industry? = nil) {
        switch phase {
        case .waiting, .complete:
            break
        case .industrySelection:
            playAmbientMusic()
        case .buildingTension:
            playTransition()
        case .industryVignette:
            playTransition()
        case .patternBreak:
            playTensionTone()
        case .suckerPunchReveal:
            // Handled by view with precise timing
            break
        case .comparisonCarousel:
            playCardWhoosh()
        case .agenticOrchestration:
            transitionToUpbeatMusic()
            playReveal()
        case .automationAnywhereReveal:
            playReveal()
        case .humanReturn:
            playReveal()
        case .callToAction:
            playCompletion()
        }
    }
}

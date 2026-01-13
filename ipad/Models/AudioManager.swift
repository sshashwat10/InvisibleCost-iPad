import Foundation
import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Enhanced Audio Manager
/// Comprehensive audio management for the enhanced Invisible Cost experience
/// Handles narration, ambient sounds, transition effects, and precise sync points
/// NOW WITH PROPER COMPLETION CALLBACKS FOR PHASE SYNCHRONIZATION

@Observable
class AudioManager: NSObject, AVAudioPlayerDelegate {
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

    // MARK: - Completion Callbacks
    private var narrationCompletionHandler: (() -> Void)?
    private var narrationCompletionTimer: Timer?

    // MARK: - Audio Duration Cache
    /// Cached durations for all narration files (key: filename, value: duration in seconds)
    private var audioDurationCache: [String: TimeInterval] = [:]

    // MARK: - Actual Narration Durations (measured from audio files)
    /// These are the actual durations of the narration audio files in seconds
    /// Updated based on afinfo measurements of the MP3 files
    static let estimatedDurations: [String: TimeInterval] = [
        // Emotional Intro (Opening narrations)
        "opening_1": 4.0,        // narration_opening_1.mp3: "Every organization carries a hidden cost."
        "opening_2": 3.5,        // narration_opening_2.mp3: "Most leaders never see it."

        // Industry Selection
        "choose_industry": 8.0,  // narration_choose_industry.mp3: 7.967s

        // Personalization Input
        "personal_input": 9.0,   // narration_personal_input.mp3: 8.96s

        // Building Tension (per industry)
        "building_finance": 15.4,  // narration_building_finance.mp3: 15.360s
        "building_supply": 15.0,   // narration_building_supply.mp3: 14.994s
        "building_health": 13.0,   // narration_building_health.mp3: 12.904s

        // Industry Vignettes
        "vignette_finance_enhanced": 5.6,  // narration_vignette_finance_enhanced.mp3: ~5.5s
        "vignette_supply_enhanced": 3.7,   // narration_vignette_supply_enhanced.mp3: ~3.6s
        "vignette_health_enhanced": 4.0,   // narration_vignette_health_enhanced.mp3: ~3.9s

        // Pattern Break
        "pattern_break_enhanced": 6.0,  // narration_pattern_break_enhanced.mp3: 5.851s

        // Sucker Punch (per industry)
        "sucker_punch_finance": 15.3,  // narration_sucker_punch_finance.mp3: 15.229s
        "sucker_punch_supply": 11.2,   // narration_sucker_punch_supply.mp3: 11.128s
        "sucker_punch_health": 13.7,   // narration_sucker_punch_health.mp3: 13.609s

        // Comparisons (per industry, 3 each)
        "comparison_finance_1": 5.8,   // narration_comparison_finance_1.mp3: 5.799s
        "comparison_finance_2": 3.5,   // narration_comparison_finance_2.mp3: 3.474s
        "comparison_finance_3": 4.4,   // narration_comparison_finance_3.mp3: 4.362s
        "comparison_supply_1": 3.0,    // narration_comparison_supply_1.mp3: 2.925s
        "comparison_supply_2": 3.4,    // narration_comparison_supply_2.mp3: 3.369s
        "comparison_supply_3": 4.4,    // narration_comparison_supply_3.mp3: 4.310s
        "comparison_health_1": 5.0,    // narration_comparison_health_1.mp3: 4.963s
        "comparison_health_2": 3.9,    // narration_comparison_health_2.mp3: 3.840s
        "comparison_health_3": 2.9,    // narration_comparison_health_3.mp3: 2.873s

        // Solution
        "agentic_enhanced": 12.6,      // narration_agentic_enhanced.mp3: 12.564s
        "aa_reveal_enhanced": 5.4,     // narration_aa_reveal_enhanced.mp3: 5.328s

        // Human Return
        "restoration_enhanced": 3.0,   // narration_restoration_enhanced.mp3: 2.925s
        "breathe": 2.5,                // narration_breathe.mp3: 2.403s
        "purpose": 7.4,                // narration_purpose.mp3: 7.340s

        // Final CTA
        "final_cta_enhanced": 10.2,    // narration_final_cta_enhanced.mp3: 10.109s
        "ready_change": 2.7            // narration_ready_change.mp3: ~2.6s
    ]

    // MARK: - Initialization

    override private init() {
        super.init()
        setupAudioSession()
        setupAudioEngine()
        cacheAllAudioDurations()
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

    // MARK: - Audio Duration Caching

    private func cacheAllAudioDurations() {
        let narrationKeys = [
            "opening_1", "opening_2",  // Emotional intro
            "choose_industry",
            "personal_input",  // NEW
            "building_finance", "building_supply", "building_health",
            "vignette_finance_enhanced", "vignette_supply_enhanced", "vignette_health_enhanced",
            "pattern_break_enhanced",
            "sucker_punch_finance", "sucker_punch_supply", "sucker_punch_health",
            "comparison_finance_1", "comparison_finance_2", "comparison_finance_3",
            "comparison_supply_1", "comparison_supply_2", "comparison_supply_3",
            "comparison_health_1", "comparison_health_2", "comparison_health_3",
            "agentic_enhanced", "aa_reveal_enhanced",
            "restoration_enhanced", "breathe", "purpose",
            "final_cta_enhanced", "ready_change"
        ]

        for key in narrationKeys {
            if let duration = getAudioFileDuration(for: key) {
                audioDurationCache[key] = duration
                print("[Audio] Cached duration for \(key): \(String(format: "%.1f", duration))s")
            }
        }
    }

    private func getAudioFileDuration(for key: String) -> TimeInterval? {
        let formats = ["mp3", "m4a", "wav", "aiff", "caf"]
        var filenamesToTry = ["narration_\(key)"]
        if key.hasSuffix("_enhanced") {
            let baseKey = String(key.dropLast("_enhanced".count))
            filenamesToTry.append("narration_\(baseKey)")
        }

        for filename in filenamesToTry {
            for format in formats {
                if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                    do {
                        let player = try AVAudioPlayer(contentsOf: url)
                        return player.duration
                    } catch {
                        continue
                    }
                }
            }
        }
        return nil
    }

    /// Get the duration for a narration key (from cache, file, or estimate)
    func getNarrationDuration(for key: String) -> TimeInterval {
        // First check cache
        if let cached = audioDurationCache[key] {
            return cached
        }

        // Try to get from file
        if let fileDuration = getAudioFileDuration(for: key) {
            audioDurationCache[key] = fileDuration
            return fileDuration
        }

        // Fall back to estimates
        if let estimate = AudioManager.estimatedDurations[key] {
            return estimate
        }

        // Default fallback
        return 5.0
    }

    // MARK: - Narration Playback

    /// Enhanced narration scripts for all phases
    private let narratorLines: [String: String] = [
        // Emotional Intro (Opening narrations)
        "opening_1": "Every organization carries a hidden cost.",
        "opening_2": "Most leaders never see it.",

        // Industry Selection
        "choose_industry": "Choose your industry. See your invisible cost.",

        // Personalization Input
        "personal_input": "Now let's see YOUR invisible cost. How many people on your team? How many hours each week lost to work that doesn't need humans?",

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
    /// The completion handler is called when the audio finishes playing
    func playNarration(for key: String, completion: (() -> Void)? = nil) {
        // Cancel any existing completion timer
        narrationCompletionTimer?.invalidate()
        narrationCompletionTimer = nil

        currentNarrationKey = key
        narrationCompletionHandler = completion

        // Try to find and play pre-recorded narration
        if playPreRecordedNarration(for: key) {
            return
        }

        // Fallback to TTS
        guard let text = narratorLines[key] else {
            print("[Audio] No narration found for key: \(key)")
            isNarrationPlaying = false
            completion?()
            return
        }

        speakNarration(text)
    }

    private func playPreRecordedNarration(for key: String) -> Bool {
        let formats = ["mp3", "m4a", "wav", "aiff", "caf"]

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
                        narrationPlayer?.delegate = self
                        narrationPlayer?.prepareToPlay()

                        isNarrationPlaying = true
                        narrationPlayer?.play()

                        let duration = narrationPlayer?.duration ?? 2.0
                        print("[Audio] Playing: \(filename).\(format) (duration: \(String(format: "%.1f", duration))s)")

                        // Set up a backup timer in case delegate doesn't fire
                        // Add a small buffer for safety
                        narrationCompletionTimer = Timer.scheduledTimer(withTimeInterval: duration + 0.3, repeats: false) { [weak self] _ in
                            self?.handleNarrationCompletion()
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

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === narrationPlayer {
            handleNarrationCompletion()
        }
    }

    private func handleNarrationCompletion() {
        // Cancel the backup timer
        narrationCompletionTimer?.invalidate()
        narrationCompletionTimer = nil

        isNarrationPlaying = false
        let key = currentNarrationKey ?? "unknown"
        currentNarrationKey = nil

        print("[Audio] Narration completed: \(key)")

        // Call completion handler on main thread
        DispatchQueue.main.async { [weak self] in
            self?.narrationCompletionHandler?()
            self?.narrationCompletionHandler = nil
        }
    }

    private func speakNarration(_ text: String) {
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

        narrationCompletionTimer = Timer.scheduledTimer(withTimeInterval: estimatedDuration, repeats: false) { [weak self] _ in
            self?.handleNarrationCompletion()
        }
    }

    func stopNarration() {
        narrationPlayer?.stop()
        narrationCompletionTimer?.invalidate()
        narrationCompletionTimer = nil
        isNarrationPlaying = false
        currentNarrationKey = nil
        narrationCompletionHandler = nil
    }

    /// Check if a specific narration is currently playing
    func isPlaying(narration key: String) -> Bool {
        return isNarrationPlaying && currentNarrationKey == key
    }

    // MARK: - Sound Effects

    func playSelectionSound() {
        playEffect("sfx_selection", fallback: self.generateSelectionBuffer(), name: "Selection")
        triggerHaptic(.medium)
    }

    func playSuckerPunchImpact() {
        playEffect("sfx_impact_boom", fallback: self.generateImpactBuffer(), name: "Impact")
        triggerHaptic(.heavy)
    }

    func playCounterTick() {
        playEffect("sfx_counting_tick", fallback: self.generateTickBuffer(), name: "Tick")
    }

    func playCardWhoosh() {
        playEffect("sfx_card_whoosh", fallback: self.generateWhooshBuffer(), name: "Whoosh")
        triggerHaptic(.light)
    }

    func playTransition() {
        playEffect("sfx_transition", fallback: self.generateTransitionBuffer(), name: "Transition")
    }

    func playReveal() {
        playEffect("sfx_reveal", fallback: self.generateRevealBuffer(), name: "Reveal")
    }

    func playCompletion() {
        playEffect("sfx_completion", fallback: self.generateCompletionBuffer(), name: "Completion")
    }

    func playUIFeedback() {
        AudioServicesPlaySystemSound(1104)
    }

    func playTensionTone() {
        playEffect("sfx_tension_tone", fallback: self.generateTensionBuffer(), name: "Tension")
    }

    func playReadyChime() {
        playEffect("sfx_ready_chime", fallback: self.generateReadyBuffer(), name: "Ready")
    }

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

        preloadUpbeatMusic()

        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: "ambient_music", withExtension: format) {
                do {
                    ambientMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientMusicPlayer?.numberOfLoops = -1
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

    /// Full reset for restart - stops all audio and resets state to initial
    /// Called when user taps restart to ensure BGM starts fresh
    func resetForRestart() {
        print("[Audio] Full reset for restart")

        // Stop all players immediately
        narrationPlayer?.stop()
        narrationPlayer = nil
        ambientMusicPlayer?.stop()
        ambientMusicPlayer = nil
        upbeatMusicPlayer?.stop()
        upbeatMusicPlayer = nil
        effectPlayer?.stop()
        effectPlayer = nil

        // Stop engine nodes
        ambientPlayerNode.stop()
        effectPlayerNode.stop()

        // Cancel any pending timers
        narrationCompletionTimer?.invalidate()
        narrationCompletionTimer = nil

        // Reset all state flags
        isAmbientPlaying = false
        isNarrationPlaying = false
        isUpbeatMode = false
        currentNarrationKey = nil
        narrationCompletionHandler = nil

        // Re-preload upbeat music for the new session
        preloadUpbeatMusic()

        print("[Audio] Reset complete - ready for new experience")
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
            let lowFreq = sin(2.0 * .pi * 60.0 * t) * exp(-t * 5) * 0.5
            let midFreq = sin(2.0 * .pi * 120.0 * t) * exp(-t * 8) * 0.3
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
        case .emotionalIntro:
            // Ambient music starts immediately for emotional intro
            playAmbientMusic()
        case .industrySelection:
            // Ambient music should already be playing from intro
            if !isAmbientPlaying {
                playAmbientMusic()
            }
        case .personalInput:
            playTransition()  // Subtle transition sound
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

    /// Calculate the minimum duration needed for a phase based on its narrations
    /// TIGHTENED - reduced buffers to eliminate dead space
    func getMinimumPhaseDuration(for phase: Tier1Phase, industry: Industry?) -> TimeInterval {
        let buffer: TimeInterval = 1.5 // Tighter breathing room (was 2.0)

        switch phase {
        case .waiting, .complete:
            return 0

        case .emotionalIntro:
            // Fixed 15 seconds - snappy timed phase with two narrations
            // Narrations are triggered at specific progress points, not sequentially
            return 15.0

        case .industrySelection:
            return getNarrationDuration(for: "choose_industry") + buffer

        case .personalInput:
            return getNarrationDuration(for: "personal_input") + buffer

        case .buildingTension:
            guard let industry = industry else { return 12.0 }
            let key = "building_\(industry.rawValue)"
            return getNarrationDuration(for: key) + buffer + 1.0 // Reduced from +2.0

        case .industryVignette:
            guard let industry = industry else { return 8.0 }
            let key = "vignette_\(industry.rawValue)_enhanced"
            return getNarrationDuration(for: key) + buffer + 2.0 // Reduced from +6.0

        case .patternBreak:
            return 0 // User-controlled

        case .suckerPunchReveal:
            return 0 // User-controlled

        case .comparisonCarousel:
            return 0 // User-controlled

        case .agenticOrchestration:
            let narrationDuration = getNarrationDuration(for: "agentic_enhanced")
            return max(15.0, narrationDuration + buffer + 2.0) // Reduced from +10.0

        case .automationAnywhereReveal:
            let narrationDuration = getNarrationDuration(for: "aa_reveal_enhanced")
            return max(8.0, narrationDuration + buffer + 1.0) // Reduced from +3.0

        case .humanReturn:
            // Multiple narrations in sequence - tighter spacing
            let restoration = getNarrationDuration(for: "restoration_enhanced")
            let breathe = getNarrationDuration(for: "breathe")
            let purpose = getNarrationDuration(for: "purpose")
            return restoration + breathe + purpose + buffer * 2 + 1.5 // Reduced from buffer*3 + 3.0

        case .callToAction:
            return 0 // User-controlled, but should wait for narration
        }
    }
}

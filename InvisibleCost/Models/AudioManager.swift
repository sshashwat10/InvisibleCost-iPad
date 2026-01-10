import Foundation
import AVFoundation

/// Audio manager for the Invisible Cost Vision Pro experience
/// Handles narration, ambient sounds, and audio effects
/// 
/// NOTE: For true spatial audio in Vision Pro, use RealityKit's
/// SpatialAudioComponent attached to entities in ImmersiveNarrativeView.
/// This manager handles the audio content; positioning is done in 3D space.
@Observable
class AudioManager {
    static let shared = AudioManager()
    
    // Audio players
    private var narrationPlayer: AVAudioPlayer?
    private var ambientMusicPlayer: AVAudioPlayer?
    private var upbeatMusicPlayer: AVAudioPlayer?
    private var effectPlayer: AVAudioPlayer?
    
    // Speech synthesizer for fallback
    private let synthesizer = AVSpeechSynthesizer()
    
    // State
    private(set) var isAmbientPlaying = false
    private(set) var isNarrationPlaying = false
    private var isUpbeatMode = false
    
    // Volume controls - optimized for Vision Pro immersion
    var ambientVolume: Float = 0.10  // Slightly higher for spatial presence
    var narrationVolume: Float = 1.0
    var effectsVolume: Float = 0.60
    
    // Track triggered audio (prevents re-triggers)
    private var triggeredAudio: Set<String> = []
    
    // Current phase tracking for dynamic audio adjustments
    private(set) var currentPhase: NarrativePhase = .waiting
    
    private init() {
        setupAudioSession()
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
    
    // MARK: - Reset Triggers (for new experience)
    
    func resetTriggers() {
        triggeredAudio.removeAll()
        isUpbeatMode = false
    }
    
    func stopAllAudio() {
        narrationPlayer?.stop()
        ambientMusicPlayer?.stop()
        upbeatMusicPlayer?.stop()
        effectPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        isAmbientPlaying = false
        isNarrationPlaying = false
    }
    
    // MARK: - Ambient Music
    
    func playAmbientHum() {
        guard !isAmbientPlaying else { return }
        
        preloadUpbeatMusic()
        
        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: "ambient_music", withExtension: format) {
                do {
                    ambientMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientMusicPlayer?.numberOfLoops = 0
                    ambientMusicPlayer?.volume = ambientVolume
                    ambientMusicPlayer?.prepareToPlay()
                    ambientMusicPlayer?.play()
                    
                    isAmbientPlaying = true
                    print("🎵 Ambient music started")
                    return
                } catch {
                    print("⚠️ Failed to play ambient music: \(error)")
                }
            }
        }
        
        print("📝 No ambient_music file found")
    }
    
    private func preloadUpbeatMusic() {
        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: "upbeat_music", withExtension: format) {
                do {
                    upbeatMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    upbeatMusicPlayer?.numberOfLoops = 0
                    upbeatMusicPlayer?.volume = ambientVolume * 1.2
                    upbeatMusicPlayer?.prepareToPlay()
                    print("🎵 Upbeat music preloaded")
                    return
                } catch {
                    print("⚠️ Failed to preload upbeat music: \(error)")
                }
            }
        }
    }
    
    func startUpbeatMusic() {
        guard !isUpbeatMode else { return }
        isUpbeatMode = true
        
        // Fade out ambient
        if let ambient = ambientMusicPlayer, ambient.isPlaying {
            fadeOut(player: ambient, duration: 1.0)
        }
        
        // Start upbeat after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.upbeatMusicPlayer?.volume = 0.0
            self?.upbeatMusicPlayer?.play()
            self?.fadeIn(player: self?.upbeatMusicPlayer, duration: 1.5, targetVolume: (self?.ambientVolume ?? 0.08) * 1.2)
            print("🎵 Upbeat music started")
        }
    }
    
    func fadeOutUpbeatMusic(duration: TimeInterval = 5.0) {
        if let upbeat = upbeatMusicPlayer, upbeat.isPlaying {
            fadeOut(player: upbeat, duration: duration)
        }
    }
    
    func stopAllAmbient() {
        ambientMusicPlayer?.stop()
        upbeatMusicPlayer?.stop()
        isAmbientPlaying = false
    }
    
    // MARK: - Narration
    
    /// Narration texts (fallback if MP3 not found) - 1:1 PARITY with iPad
    private let narratorLines: [String: String] = [
        // Opening - matches iPad exactly
        "opening_1": "There's something your organization doesn't talk about.",
        "opening_2": "A silent drain on every leader, every team, every single day.",
        "opening_3": "Hundreds of decisions that should never have been yours.",
        
        // Vignettes - matches iPad exactly
        "vignette_finance": "Hours lost to tasks that machines were made for.",
        "vignette_supply": "Brilliant minds trapped in busywork.",
        "vignette_health": "Healers buried under paperwork.",
        
        // Pattern break
        "pattern_break": "But what if tomorrow looked different?",
        
        // Agentic - matches iPad exactly
        "agentic": "This is Agentic Orchestration. Intelligence that anticipates. Acts. And frees you to think.",
        
        // Human return
        "restoration": "The chains dissolve. One by one.",
        "human_return": "And suddenly you remember what it feels like to breathe.",
        "potential": "This is what happens when machines handle the mechanics and humans reclaim their purpose.",
        
        // Closing - matches iPad exactly
        "vision": "Picture a world where strategists think bigger. Innovators move faster. Leaders focus on what truly matters.",
        "closing": "When your people are free, everything changes. Innovation accelerates. Sustainability becomes possible. People thrive.",
        "proof": "This isn't tomorrow. Organizations are living this today.",
        "question": "With Automation Anywhere, you have the power to lead in a world that demands more.",
        "final_cta": "The invisible cost... ends now. The future of work... starts here."
    ]
    
    func playNarration(for key: String) {
        guard !triggeredAudio.contains("narration_\(key)") else { return }
        triggeredAudio.insert("narration_\(key)")
        
        // Try MP3 file first
        let filename = "narration_\(key)"
        let formats = ["mp3", "m4a", "wav"]
        
        for format in formats {
            if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                do {
                    narrationPlayer = try AVAudioPlayer(contentsOf: url)
                    narrationPlayer?.volume = narrationVolume
                    narrationPlayer?.prepareToPlay()
                    narrationPlayer?.play()
                    
                    isNarrationPlaying = true
                    print("🎙️ Playing narration: \(filename).\(format)")
                    return
                } catch {
                    print("⚠️ Failed to play narration file: \(error)")
                }
            }
        }
        
        // Fallback to TTS
        if let text = narratorLines[key] {
            speakNarration(text)
        }
    }
    
    private func speakNarration(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 0.95
        utterance.volume = narrationVolume
        
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-GB.Daniel") {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "en-GB") {
            utterance.voice = voice
        }
        
        synthesizer.speak(utterance)
        isNarrationPlaying = true
        print("🎙️ TTS narration: \(text.prefix(40))...")
    }
    
    func stopNarration() {
        narrationPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        isNarrationPlaying = false
    }
    
    // MARK: - Sound Effects
    
    func playEffect(named effectName: String) {
        guard !triggeredAudio.contains("effect_\(effectName)") else { return }
        triggeredAudio.insert("effect_\(effectName)")
        
        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: effectName, withExtension: format) {
                do {
                    effectPlayer = try AVAudioPlayer(contentsOf: url)
                    effectPlayer?.volume = effectsVolume
                    effectPlayer?.prepareToPlay()
                    effectPlayer?.play()
                    print("🔊 Playing effect: \(effectName)")
                    return
                } catch {
                    print("⚠️ Failed to play effect: \(error)")
                }
            }
        }
    }
    
    // Convenience methods for specific effects
    func playTransition() { playEffect(named: "sfx_transition") }
    func playReveal() { playEffect(named: "sfx_reveal") }
    func playCompletion() { playEffect(named: "sfx_completion") }
    func playSphereForming() { playEffect(named: "sfx_sphere_forming") }
    func playConnection() { playEffect(named: "sfx_connection") }
    func playDotAppear() { playEffect(named: "sfx_dot_appear") }
    func playLineForming() { playEffect(named: "sfx_line_forming") }
    func playSpherePulse() { playEffect(named: "sfx_pulse") }
    func playSphereShrink() { playEffect(named: "sfx_shrink") }
    func playUIFeedback() { playEffect(named: "sfx_ui_feedback") }
    func transitionToUpbeatMusic(crossfadeDuration: TimeInterval = 1.0) { startUpbeatMusic() }
    
    // MARK: - Phase Audio Triggers (1:1 PARITY with iPad)
    
    func playAudioForPhase(_ phase: NarrativePhase, progress: Double) {
        // Track current phase for spatial audio adjustments
        currentPhase = phase
        
        switch phase {
        case .microColdOpen:
            // Start ambient immediately
            triggerOnce("ambient_start", at: 0.01, progress: progress) {
                self.playAmbientHum()
            }
            
        case .narratorFrame:
            // Phase duration: 17s - balanced pacing (matches iPad)
            triggerOnce("opening_1", at: 0.05, progress: progress) {
                self.playNarration(for: "opening_1")
            }
            triggerOnce("opening_2", at: 0.36, progress: progress) {
                self.playNarration(for: "opening_2")
            }
            triggerOnce("opening_3", at: 0.68, progress: progress) {
                self.playNarration(for: "opening_3")
            }
            
        case .spatialOverwhelm:
            // Phase duration: 5s - tight vignette (matches iPad's 15s / 3)
            triggerOnce("vignette_finance", at: 0.10, progress: progress) {
                self.playNarration(for: "vignette_finance")
            }
            
        case .realityCrack:
            // Phase duration: 5s
            triggerOnce("vignette_supply", at: 0.10, progress: progress) {
                self.playNarration(for: "vignette_supply")
            }
            
        case .humanFragment:
            // Phase duration: 5s
            triggerOnce("vignette_health", at: 0.10, progress: progress) {
                self.playNarration(for: "vignette_health")
            }
            
        case .patternBreak:
            // Phase duration: 6s (matches iPad)
            triggerOnce("pattern_break", at: 0.20, progress: progress) {
                self.playNarration(for: "pattern_break")
            }
            triggerOnce("transition_sfx", at: 0.65, progress: progress) {
                self.playTransition()
            }
            
        case .agenticOrchestration:
            // Phase duration: 24s (matches iPad) - THE AWAKENING
            triggerOnce("upbeat_start", at: 0.01, progress: progress) {
                self.startUpbeatMusic()
            }
            triggerOnce("reveal_sfx", at: 0.03, progress: progress) {
                self.playReveal()
            }
            // Dot appear sounds (matches iPad)
            triggerOnce("dot_01", at: 0.04, progress: progress) { self.playDotAppear() }
            triggerOnce("dot_02", at: 0.08, progress: progress) { self.playDotAppear() }
            triggerOnce("dot_03", at: 0.12, progress: progress) { self.playDotAppear() }
            triggerOnce("dot_04", at: 0.16, progress: progress) { self.playDotAppear() }
            triggerOnce("dot_05", at: 0.20, progress: progress) { self.playDotAppear() }
            // Line forming sounds
            triggerOnce("line_01", at: 0.26, progress: progress) { self.playLineForming() }
            triggerOnce("line_02", at: 0.32, progress: progress) { self.playLineForming() }
            triggerOnce("line_03", at: 0.38, progress: progress) { self.playLineForming() }
            triggerOnce("line_04", at: 0.44, progress: progress) { self.playLineForming() }
            // Pulse sounds
            triggerOnce("pulse_1", at: 0.50, progress: progress) { self.playSpherePulse() }
            triggerOnce("pulse_2", at: 0.56, progress: progress) { self.playSpherePulse() }
            // Narration at 62% (matches iPad)
            triggerOnce("agentic", at: 0.62, progress: progress) {
                self.playNarration(for: "agentic")
            }
            
        case .humanReturn:
            // Phase duration: 18s (matches iPad)
            triggerOnce("reveal_sfx", at: 0.05, progress: progress) {
                self.playReveal()
            }
            triggerOnce("restoration", at: 0.10, progress: progress) {
                self.playNarration(for: "restoration")
            }
            triggerOnce("human_return", at: 0.32, progress: progress) {
                self.playNarration(for: "human_return")
            }
            triggerOnce("potential", at: 0.58, progress: progress) {
                self.playNarration(for: "potential")
            }
            
        case .personalization:
            // Calm phase - UI feedback only
            break
            
        case .stillnessCTA:
            // Phase duration: 50s (matches iPad)
            triggerOnce("vision", at: 0.04, progress: progress) {
                self.playNarration(for: "vision")
            }
            triggerOnce("closing", at: 0.18, progress: progress) {
                self.playNarration(for: "closing")
            }
            triggerOnce("proof", at: 0.34, progress: progress) {
                self.playNarration(for: "proof")
            }
            triggerOnce("question", at: 0.50, progress: progress) {
                self.playNarration(for: "question")
            }
            triggerOnce("final_cta", at: 0.70, progress: progress) {
                self.playNarration(for: "final_cta")
            }
            triggerOnce("music_fadeout", at: 0.72, progress: progress) {
                self.fadeOutUpbeatMusic(duration: 10.0)
            }
            triggerOnce("completion_sfx", at: 0.92, progress: progress) {
                self.playCompletion()
            }
            
        case .waiting, .complete:
            break
        }
    }
    
    // MARK: - Helpers
    
    private func triggerOnce(_ id: String, at threshold: Double, progress: Double, action: () -> Void) {
        guard progress >= threshold && !triggeredAudio.contains(id) else { return }
        triggeredAudio.insert(id)
        action()
    }
    
    private func fadeOut(player: AVAudioPlayer, duration: TimeInterval) {
        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                player.volume = max(0, player.volume - volumeStep)
                if i == steps - 1 {
                    player.stop()
                }
            }
        }
    }
    
    private func fadeIn(player: AVAudioPlayer?, duration: TimeInterval, targetVolume: Float) {
        guard let player = player else { return }
        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = targetVolume / Float(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                player.volume = min(targetVolume, player.volume + volumeStep)
            }
        }
    }
}

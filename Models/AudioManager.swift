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
    
    // Volume controls - balanced mix hierarchy
    // Ambient is lowest (background bed), effects sit above, narration is clearest
    var ambientVolume: Float = 0.08      // Very low - fills silence, never competes
    var narrationVolume: Float = 1.0      // Full volume - always clear
    var effectsVolume: Float = 0.55       // Raised to ensure subtle sounds cut through ambient
    
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
    
    // MARK: - Music System (Ambient → Upbeat Transition)
    
    /// Audio player for ambient background music (opening phases)
    private var ambientMusicPlayer: AVAudioPlayer?
    /// Audio player for upbeat/EDM music (from agentic orchestration onwards)
    private var upbeatMusicPlayer: AVAudioPlayer?
    /// Track which music mode is active
    private var isUpbeatMode = false
    
    /// Play ambient background music (loops until transition)
    /// 
    /// Add music files to your project:
    /// - ambient_music.mp3: Ethereal pads, subtle tension (0:00 - 1:06)
    /// - upbeat_music.mp3: EDM/upbeat drop, energizing (1:06 - 3:00)
    /// 
    /// Transition happens at agenticOrchestration phase
    ///
    func playAmbientHum() {
        guard !isAmbientPlaying else { return }
        
        // Preload upbeat music for seamless transition
        preloadUpbeatMusic()
        
        // Try to play ambient music file first
        if playAmbientMusicFile() {
            return
        }
        
        // Fallback to synthesized ambient (if no file)
        isAmbientPlaying = true
        ambientPlayerNode.volume = ambientVolume
        
        let buffer = generateAmbientBuffer(duration: 10.0)
        ambientPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops) { }
        ambientPlayerNode.play()
        print("🔊 Ambient (synthesized) started")
    }
    
    /// Attempts to play an ambient music file
    private func playAmbientMusicFile() -> Bool {
        let formats = ["mp3", "m4a", "wav", "aiff", "caf"]
        
        for format in formats {
            if let url = Bundle.main.url(forResource: "ambient_music", withExtension: format) {
                do {
                    ambientMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientMusicPlayer?.numberOfLoops = 0  // No loop - will transition to upbeat
                    ambientMusicPlayer?.volume = ambientVolume
                    ambientMusicPlayer?.prepareToPlay()
                    ambientMusicPlayer?.play()
                    
                    isAmbientPlaying = true
                    print("🎵 Ambient music started: ambient_music.\(format)")
                    return true
                } catch {
                    print("⚠️ Failed to play ambient music: \(error)")
                }
            }
        }
        
        print("📝 No ambient_music file found - using synthesized fallback")
        return false
    }
    
    /// Preload upbeat music for seamless transition
    private func preloadUpbeatMusic() {
        let formats = ["mp3", "m4a", "wav", "aiff", "caf"]
        
        for format in formats {
            if let url = Bundle.main.url(forResource: "upbeat_music", withExtension: format) {
                do {
                    upbeatMusicPlayer = try AVAudioPlayer(contentsOf: url)
                    upbeatMusicPlayer?.numberOfLoops = 0  // Play once through
                    upbeatMusicPlayer?.volume = 0  // Start silent for crossfade
                    upbeatMusicPlayer?.prepareToPlay()
                    print("🎵 Upbeat music preloaded: upbeat_music.\(format)")
                    return
                } catch {
                    print("⚠️ Failed to preload upbeat music: \(error)")
                }
            }
        }
        print("📝 No upbeat_music file found - ambient will continue")
    }
    
    /// Crossfade transition from ambient to upbeat music (EDM drop moment)
    /// Call this at the start of agenticOrchestration phase
    func transitionToUpbeatMusic(crossfadeDuration: TimeInterval = 1.5) {
        guard !isUpbeatMode else { return }
        guard let upbeat = upbeatMusicPlayer else {
            print("📝 No upbeat music available - ambient continues")
            return
        }
        
        isUpbeatMode = true
        let upbeatVolume: Float = 0.15  // Slightly louder than ambient for energy
        
        // Start upbeat music
        upbeat.volume = 0
        upbeat.play()
        print("🎵 EDM DROP! Transitioning to upbeat music...")
        
        // Crossfade: fade out ambient, fade in upbeat
        let fadeSteps = 15
        let stepDuration = crossfadeDuration / Double(fadeSteps)
        let ambientStep = ambientVolume / Float(fadeSteps)
        let upbeatStep = upbeatVolume / Float(fadeSteps)
        
        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                guard let self = self else { return }
                
                // Fade out ambient
                let newAmbientVol = max(0, self.ambientVolume - ambientStep * Float(i + 1))
                self.ambientMusicPlayer?.volume = newAmbientVol
                self.ambientPlayerNode.volume = newAmbientVol
                
                // Fade in upbeat
                let newUpbeatVol = min(upbeatVolume, upbeatStep * Float(i + 1))
                self.upbeatMusicPlayer?.volume = newUpbeatVol
            }
        }
        
        // Stop ambient after crossfade
        DispatchQueue.main.asyncAfter(deadline: .now() + crossfadeDuration) { [weak self] in
            self?.ambientMusicPlayer?.stop()
            self?.ambientPlayerNode.stop()
            print("🎵 Crossfade complete - upbeat music active")
        }
    }
    
    /// Fade out upbeat music at the end
    func fadeOutUpbeatMusic(duration: TimeInterval = 3.0) {
        guard isUpbeatMode, let upbeat = upbeatMusicPlayer else {
            fadeOutAmbient(duration: duration)
            return
        }
        
        let originalVolume = upbeat.volume
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = originalVolume / Float(fadeSteps)
        
        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                let newVolume = max(0, originalVolume - volumeStep * Float(i + 1))
                self?.upbeatMusicPlayer?.volume = newVolume
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.upbeatMusicPlayer?.stop()
            self?.upbeatMusicPlayer = nil
            self?.isUpbeatMode = false
            self?.isAmbientPlaying = false
            print("🎵 Upbeat music faded out")
        }
    }
    
    private func generateAmbientBuffer(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        // Fallback ambient soundscape
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let sub = sin(2.0 * .pi * 55.0 * t) * 0.06
            let pad = sin(2.0 * .pi * 110.0 * t) * 0.04
            let breath = 0.8 + 0.2 * sin(t * 0.15)
            let sample = Float((sub + pad) * breath)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    /// Fade out and stop ambient sounds/music
    func fadeOutAmbient(duration: TimeInterval = 2.0) {
        guard isAmbientPlaying else { return }
        
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let originalVolume = ambientVolume
        let volumeStep = originalVolume / Float(fadeSteps)
        
        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                let newVolume = originalVolume - volumeStep * Float(i + 1)
                self?.ambientPlayerNode.volume = newVolume
                self?.ambientMusicPlayer?.volume = newVolume
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopAmbient()
            self?.ambientPlayerNode.volume = originalVolume
        }
    }
    
    func stopAmbient() {
        ambientPlayerNode.stop()
        ambientMusicPlayer?.stop()
        ambientMusicPlayer = nil
        upbeatMusicPlayer?.stop()
        upbeatMusicPlayer = nil
        isAmbientPlaying = false
        isUpbeatMode = false
    }
    
    // MARK: - Narration
    
    // MARK: - Narration Audio
    
    /// Audio player for pre-recorded narration
    private var narrationPlayer: AVAudioPlayer?
    
    /// Narrator lines for each phase (used for TTS fallback)
    /// Audio file naming: narration_{key}.m4a (e.g., narration_opening_1.m4a)
    /// NOTE: Each line should FLOW into the next - use trailing tone, connecting words
    /// DAVOS 2026 THEMES (in outro): Cooperation, Innovation, AI Governance, Climate, Economic Growth, People, Planetary Boundaries
    private let narratorLines: [String: String] = [
        // Opening - definitive full stops
        "opening_1": "There's something your organization doesn't talk about.",
        "opening_2": "A silent drain on every leader, every team, every single day.",
        "opening_3": "Imagine being freed from repetitive, mundane tasks.",
        
        // Vignettes - definitive endings
        "vignette_finance": "Hours lost to tasks that machines were made for.",
        "vignette_supply": "Brilliant minds trapped in busywork.",
        "vignette_health": "Healers buried under paperwork.",
        
        // Pattern break
        "pattern_break": "But what if tomorrow looked different?",

        // Agentic - periods create weight
        "agentic": "This is Agentic Solutions. Intelligence that anticipates. Acts. And frees you to think.",

        // Automation Anywhere reveal
        "aa_reveal": "From Automation Anywhere. Elevating Human Potential.",
        
        // Human return - COMPLEMENTS screen text, doesn't read it
        "restoration": "The chains dissolve. One by one.",
        "human_return": "And suddenly you remember what it feels like to breathe.",
        "potential": "This is what happens when machines handle the mechanics and humans reclaim their purpose.",
        
        // Closing - COMPLEMENTS screen text
        "vision": "Picture a world where strategists think bigger. Innovators move faster. Leaders focus on what truly matters.",
        "closing": "When your people are free, everything changes. Innovation accelerates. Sustainability becomes possible. People thrive.",
        "proof": "This isn't tomorrow. Organizations are living this today.",
        "question": "With Automation Anywhere, you have the power to lead in a world that demands more.",
        "final_cta": "The invisible cost... ends now. The future of work... starts here."
    ]
    
    /// Play narration - tries pre-recorded audio first, falls back to TTS
    /// 
    /// To use pre-recorded audio:
    /// 1. Record or generate audio files using ElevenLabs, professional voice-over, etc.
    /// 2. Name files as: narration_{key}.m4a (e.g., narration_opening_1.m4a)
    /// 3. Supported formats: .m4a, .mp3, .wav, .aiff
    /// 4. Add files to your Xcode project (drag into Assets or a Resources folder)
    /// 5. Make sure "Copy items if needed" and "Add to target" are checked
    ///
    func playNarration(for key: String, completion: (() -> Void)? = nil) {
        // Try pre-recorded audio first
        if playPreRecordedNarration(for: key, completion: completion) {
            return
        }
        
        // Fallback to TTS
        guard let text = narratorLines[key] else {
            print("⚠️ No narration found for key: \(key)")
            completion?()
            return
        }
        
        speakNarration(text, completion: completion)
    }
    
    /// Attempts to play a pre-recorded audio file for narration
    /// Returns true if audio file was found and is playing
    private func playPreRecordedNarration(for key: String, completion: (() -> Void)?) -> Bool {
        // Try different audio formats
        let formats = ["m4a", "mp3", "wav", "aiff", "caf"]
        let filename = "narration_\(key)"
        
        for format in formats {
            if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                do {
                    narrationPlayer?.stop()
                    narrationPlayer = try AVAudioPlayer(contentsOf: url)
                    narrationPlayer?.volume = narrationVolume
                    narrationPlayer?.prepareToPlay()
                    
                    isNarrationPlaying = true
                    narrationPlayer?.play()
                    
                    print("🎙️ Playing pre-recorded: \(filename).\(format)")
                    
                    // Schedule completion after audio ends
                    let duration = narrationPlayer?.duration ?? 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
                        self?.isNarrationPlaying = false
                        completion?()
                    }
                    
                    return true
                } catch {
                    print("⚠️ Failed to play \(filename).\(format): \(error)")
                }
            }
        }
        
        print("📝 No audio file for '\(key)' - using TTS fallback")
        return false
    }
    
    /// Text-to-speech fallback (used when no pre-recorded audio exists)
    private func speakNarration(_ text: String, completion: (() -> Void)?) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Try to use enhanced/premium voice if available
        // Users can download enhanced voices in Settings > Accessibility > Spoken Content > Voices
        let preferredVoices = [
            "com.apple.voice.premium.en-US.Zoe",      // Premium female
            "com.apple.voice.premium.en-US.Evan",     // Premium male
            "com.apple.voice.enhanced.en-US.Samantha", // Enhanced female
            "com.apple.voice.enhanced.en-US.Alex",    // Enhanced male
            "com.apple.ttsbundle.siri_male_en-US_compact", // Siri male
            "com.apple.ttsbundle.siri_female_en-US_compact" // Siri female
        ]
        
        var selectedVoice: AVSpeechSynthesisVoice?
        for voiceId in preferredVoices {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                selectedVoice = voice
                break
            }
        }
        
        // Fallback to default English voice
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.rate = 0.48
        utterance.pitchMultiplier = 0.95  // Slightly lower pitch for gravitas
        utterance.volume = narrationVolume
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.25
        
        isNarrationPlaying = true
        print("🎙️ TTS Narrating: \"\(text)\"")
        
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
        synthesizer.stopSpeaking(at: .immediate)
        isNarrationPlaying = false
    }
    
    // MARK: - Sound Effects
    // Uses pre-recorded audio files (generated via ElevenLabs) with synthesized fallback
    
    /// Audio player for sound effects
    private var effectPlayer: AVAudioPlayer?
    
    /// Play a sound effect - tries pre-recorded file first, falls back to synthesized
    private func playSoundEffect(filename: String, fallbackBuffer: @autoclosure () -> AVAudioPCMBuffer, name: String) {
        // Try pre-recorded file first
        let formats = ["mp3", "m4a", "wav"]
        for format in formats {
            if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                do {
                    effectPlayer?.stop()
                    effectPlayer = try AVAudioPlayer(contentsOf: url)
                    effectPlayer?.volume = effectsVolume
                    effectPlayer?.prepareToPlay()
                    effectPlayer?.play()
                    print("🔔 \(name) (file)")
                    return
                } catch {
                    print("⚠️ Failed to play \(filename).\(format): \(error)")
                }
            }
        }
        
        // Fallback to synthesized
        let buffer = fallbackBuffer()
        effectPlayerNode.stop()
        effectPlayerNode.volume = effectsVolume
        effectPlayerNode.scheduleBuffer(buffer, at: nil, options: []) { }
        effectPlayerNode.play()
        print("🔔 \(name) (synth)")
    }
    
    /// Play transition/whoosh sound
    func playTransition() {
        playSoundEffect(filename: "sfx_transition", fallbackBuffer: generateTransitionBuffer(), name: "Transition")
    }
    
    /// Play subtle UI feedback sound
    func playUIFeedback() {
        AudioServicesPlaySystemSound(1104) // Subtle tick
        print("🔔 UI feedback (system)")
    }
    
    /// Play reveal/appearance sound
    func playReveal() {
        playSoundEffect(filename: "sfx_reveal", fallbackBuffer: generateRevealBuffer(), name: "Reveal")
    }
    
    /// Play completion/success sound
    func playCompletion() {
        playSoundEffect(filename: "sfx_completion", fallbackBuffer: generateCompletionBuffer(), name: "Completion")
    }
    
    /// Play sphere formation sound (building up)
    func playSphereForming() {
        playSoundEffect(filename: "sfx_sphere_forming", fallbackBuffer: generateSphereFormingBuffer(), name: "Sphere forming")
    }
    
    /// Play connection sound (quick blip)
    func playConnection() {
        playSoundEffect(filename: "sfx_connection", fallbackBuffer: generateConnectionBuffer(), name: "Connection")
    }
    
    /// Play dot appearing sound (soft crystalline ping)
    func playDotAppear() {
        playSoundEffect(filename: "sfx_dot_appear", fallbackBuffer: generateDotAppearBuffer(), name: "Dot appear")
    }
    
    /// Play line forming sound (stretchy connection)
    func playLineForming() {
        playSoundEffect(filename: "sfx_line_forming", fallbackBuffer: generateLineFormingBuffer(), name: "Line forming")
    }
    
    /// Play sphere pulse sound (resonant breath)
    func playSpherePulse() {
        playSoundEffect(filename: "sfx_pulse", fallbackBuffer: generateSpherePulseBuffer(), name: "Sphere pulse")
    }
    
    /// Play sphere shrink sound (compression descent)
    func playSphereShrink() {
        playSoundEffect(filename: "sfx_shrink", fallbackBuffer: generateSphereShrinkBuffer(), name: "Sphere shrink")
    }
    
    // MARK: - MINIMAL Professional Sound Design
    // Philosophy: Subtle, understated, never distracting. Like Apple keynotes.
    // These sounds should feel almost subliminal - you notice when they're gone, not when they're there.
    
    /// Subtle random variation
    private func subtleVariation() -> Double { Double.random(in: 0.95...1.05) }
    private func subtlePan() -> Double { Double.random(in: -0.15...0.15) }
    
    private func generateTransitionBuffer() -> AVAudioPCMBuffer {
        // Barely-there whoosh - like a gentle breath of air
        let duration = 0.35
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Ultra-soft filtered noise - just air movement
            let envelope = sin(progress * .pi) * 0.12
            let noise = Double.random(in: -1...1)
            
            // Low-pass feel by averaging
            let sample = Float(noise * envelope)
            
            leftChannel[frame] = sample * 0.9
            rightChannel[frame] = sample * 1.1
        }
        
        return buffer
    }
    
    private func generateRevealBuffer() -> AVAudioPCMBuffer {
        // Soft, warm tone - like a gentle notification
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
            
            // Simple warm tone with gentle attack and long decay
            let freq = 392.0  // G4 - pleasant, not attention-grabbing
            let attack = min(t / 0.1, 1.0)
            let decay = exp(-t * 2.5)
            let envelope = attack * decay * 0.15
            
            // Pure tone with subtle warmth
            let tone = sin(2.0 * .pi * freq * t)
            let warmth = sin(2.0 * .pi * freq * 0.5 * t) * 0.3
            
            let sample = Float((tone + warmth) * envelope)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateCompletionBuffer() -> AVAudioPCMBuffer {
        // Satisfying but subtle resolution - two-note motif
        let duration = 1.0
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // Two notes: G4 then C5 (perfect fourth - pleasing resolution)
            let note1Env = exp(-t * 4) * 0.12
            let note2Env = max(0, t - 0.15) < 0.01 ? 0 : exp(-(t - 0.15) * 3) * 0.10
            
            let note1 = sin(2.0 * .pi * 392.0 * t) * note1Env  // G4
            let note2 = sin(2.0 * .pi * 523.25 * t) * note2Env  // C5
            
            let sample = Float(note1 + note2)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateSphereFormingBuffer() -> AVAudioPCMBuffer {
        // Subtle low hum that builds - almost felt more than heard
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
            
            // Deep, subtle presence that grows
            let freq = 65.0  // C2 - felt in the chest
            let intensity = pow(progress, 1.5) * 0.15
            
            let sub = sin(2.0 * .pi * freq * t) * intensity
            let octave = sin(2.0 * .pi * freq * 2 * t) * intensity * 0.3
            
            let sample = Float(sub + octave)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateConnectionBuffer() -> AVAudioPCMBuffer {
        // Tiny, soft tick - like a gentle tap
        let duration = 0.06
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        let pan = subtlePan()
        let pitch = 800.0 * subtleVariation()
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // Quick, soft click
            let envelope = exp(-t * 60) * 0.08
            let tone = sin(2.0 * .pi * pitch * t)
            
            let sample = Float(tone * envelope)
            leftChannel[frame] = sample * Float(1.0 - pan)
            rightChannel[frame] = sample * Float(1.0 + pan)
        }
        
        return buffer
    }
    
    private func generateDotAppearBuffer() -> AVAudioPCMBuffer {
        // Soft, high ping - like a water droplet
        let duration = 0.12
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        let pan = subtlePan()
        let pitch = 1200.0 * subtleVariation()
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // Gentle, crystalline ping
            let envelope = exp(-t * 35) * 0.06
            let tone = sin(2.0 * .pi * pitch * t)
            
            let sample = Float(tone * envelope)
            leftChannel[frame] = sample * Float(1.0 - pan)
            rightChannel[frame] = sample * Float(1.0 + pan)
        }
        
        return buffer
    }
    
    private func generateLineFormingBuffer() -> AVAudioPCMBuffer {
        // Soft zip/stretch - like drawing with light
        let duration = 0.15
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        let startPan = subtlePan()
        let endPan = subtlePan()
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration
            
            // Subtle rising tone
            let freq = 400.0 + 200.0 * progress
            let envelope = sin(progress * .pi) * 0.05
            let tone = sin(2.0 * .pi * freq * t)
            
            let sample = Float(tone * envelope)
            let pan = startPan + (endPan - startPan) * progress
            leftChannel[frame] = sample * Float(1.0 - pan)
            rightChannel[frame] = sample * Float(1.0 + pan)
        }
        
        return buffer
    }
    
    private func generateSpherePulseBuffer() -> AVAudioPCMBuffer {
        // Deep, warm breath - like a heartbeat
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
            
            // Soft, organic pulse
            let freq = 80.0  // Deep but warm
            let envelope = sin(progress * .pi) * 0.12
            
            let sub = sin(2.0 * .pi * freq * t)
            let warmth = sin(2.0 * .pi * freq * 2 * t) * 0.2
            
            let sample = Float((sub + warmth) * envelope)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func generateSphereShrinkBuffer() -> AVAudioPCMBuffer {
        // Gentle descending tone - like exhaling
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
            
            // Smooth descending tone
            let freq = 200.0 - 80.0 * progress  // Gentle descent
            let envelope = (1.0 - pow(progress, 2)) * 0.10
            
            let tone = sin(2.0 * .pi * freq * t)
            let sub = sin(2.0 * .pi * freq * 0.5 * t) * 0.3
            
            let sample = Float((tone + sub) * envelope)
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
            // Keep ambient playing - don't fade out here
            break
        case .agenticOrchestration:
            playReveal()
        case .automationAnywhereReveal:
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
        case .automationAnywhereReveal:
            return ["aa_reveal"]
        case .humanReturn:
            return ["restoration", "human_return"]
        case .stillnessCTA:
            return ["closing", "question"]
        }
    }
}

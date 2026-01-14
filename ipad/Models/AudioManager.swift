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
    /// MEASURED from regenerated CLINICAL narrations (Jan 2026)
    /// Settings used: stability=0.35, similarity=0.80, style=0.15
    /// UPDATED for Department-based system (P2P, O2C, Customer Support, ITSM)
    /// Note: Clinical narrations have more substance, so durations are longer
    static let estimatedDurations: [String: TimeInterval] = [
        // Emotional Intro - Per Neeti's edit
        "opening_1": 9.0,        // "Every organization carries a hidden cost. Repetitive work. Manual processes. Lost time. And it's costing more than most leaders realize."
        "opening_2": 3.5,        // "Most leaders never quantify it. Until now."

        // Department Selection - Per Neeti's edit
        "choose_department": 4.5,  // "Choose a department and we will illustrate with an example."
        "choose_industry": 4.5,    // Legacy fallback

        // Department Input - Per Neeti's edit
        "department_input": 7.5,   // "Input your parameters to use industry benchmarks and calculate potential hidden costs."
        "personal_input": 7.5,     // Legacy fallback

        // Building Tension (per department) - Clinical and factual
        "building_p2p": 14.0,           // "Invoice processing. Every invoice requires matching... verification... approval..."
        "building_o2c": 14.0,           // "Order to cash. Every order requires processing... credit verification..."
        "building_customer_support": 13.0,  // "Customer support. Every ticket requires intake... lookup... resolution..."
        "building_itsm": 14.0,          // "IT service management. Every request requires triage... assignment... resolution..."
        "building_finance": 14.0,       // Legacy fallback
        "building_supply": 13.5,        // Legacy fallback
        "building_health": 14.0,        // Legacy fallback

        // Department Vignettes - Clinical observations
        "vignette_p2p_enhanced": 5.5,           // "Invoices accumulating. Cash flow constrained. Teams consumed by manual processing."
        "vignette_o2c_enhanced": 5.0,           // "Orders queued. Revenue delayed. Collection cycles extending."
        "vignette_customer_support_enhanced": 6.0,  // "Tickets accumulating. Response times lengthening. Agents repeating..."
        "vignette_itsm_enhanced": 5.5,          // "Requests pending. Users waiting. Technical staff consumed..."
        "vignette_finance_enhanced": 5.5,       // Legacy fallback
        "vignette_supply_enhanced": 5.0,        // Legacy fallback
        "vignette_health_enhanced": 5.5,        // Legacy fallback

        // Pattern Break - Clinical question
        "pattern_break_enhanced": 3.0,     // "What is the true operational cost?"

        // Sucker Punch - Clinical statement
        "sucker_punch_reveal": 4.5,  // "This... is your invisible cost. Annually. Exposed."
        "sucker_punch_finance": 5.5,  // Legacy fallback
        "sucker_punch_supply": 5.5,   // Legacy fallback
        "sucker_punch_health": 5.5,   // Legacy fallback

        // Cost Breakdown - Clinical explanation
        "cost_breakdown": 9.0,  // "Direct labor costs. Overhead allocation. And the hidden factors..."

        // Comparisons (per department, 3 each) - Clinical statements
        "comparison_p2p_1": 4.5,   // "Full-time employees allocated entirely to manual processing."
        "comparison_p2p_2": 4.5,   // "Budget capacity redirected from strategic initiatives."
        "comparison_p2p_3": 4.5,   // "Productive hours consumed by repetitive manual tasks."
        "comparison_o2c_1": 3.5,   // "Revenue held in accounts receivable."
        "comparison_o2c_2": 4.0,   // "Working capital unavailable for operations."
        "comparison_o2c_3": 5.0,   // "Work weeks consumed by manual collection processes."
        "comparison_customer_support_1": 4.0,  // "Agent capacity consumed by routine inquiries."
        "comparison_customer_support_2": 4.5,  // "Hours spent on questions automation could resolve."
        "comparison_customer_support_3": 4.0,  // "Customer wait time that erodes satisfaction."
        "comparison_itsm_1": 3.5,  // "Cost of password resets alone."
        "comparison_itsm_2": 4.5,  // "User productivity lost waiting for IT resolution."
        "comparison_itsm_3": 4.5,  // "Technical staff time consumed by tier-one tickets."
        "comparison_finance_1": 4.5,  // Legacy fallback
        "comparison_finance_2": 4.5,
        "comparison_finance_3": 4.5,
        "comparison_supply_1": 4.0,
        "comparison_supply_2": 4.0,
        "comparison_supply_3": 4.5,
        "comparison_health_1": 4.5,
        "comparison_health_2": 4.0,
        "comparison_health_3": 4.5,

        // Solution - Clinical explanation
        "agentic_enhanced": 12.0,     // "Now consider: automation that operates across your entire system..."
        "aa_reveal_forrester": 10.0,  // "Automation Anywhere. Industry-leading ROI. Fastest payback..."
        "aa_reveal_enhanced": 2.5,    // "Automation Anywhere."

        // AA Value Proposition (per department) - Clinical benefits
        "aa_value_p2p": 10.0,           // "Touchless invoice processing. Straight-through matching..."
        "aa_value_o2c": 6.0,           // "Accelerated collections. Compressed cycle times. Cash flow optimized."
        "aa_value_customer_support": 9.0,  // "Faster resolution. Higher satisfaction. Agents focused..."
        "aa_value_itsm": 8.5,          // "Instant provisioning. Automated resolution. IT talent redirected..."

        // Human Return - Clinical outcome
        "restoration_enhanced": 7.0,  // "Manual work... automated. Repetitive processes... eliminated. Capacity... restored."
        "breathe": 3.5,               // "This is what operational efficiency looks like."
        "purpose": 9.0,               // "Strategy instead of spreadsheets. Innovation instead of administration..."

        // Final CTA - Per Neeti's edit
        "final_cta_enhanced": 7.5,    // "Say no to invisible costs. The question is: what will you do with the capacity you recover?"
        "ready_change": 3.0           // "Ready to recover this capacity?"
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
            // DEMO-SAFE: Use spokenAudio mode for reliable narration
            // - On Vision Pro: Makes narration non-spatial (head-locked, no distance artifacts)
            // - On iPad: Optimizes for voice clarity
            // - duckOthers: Lowers other audio when narration plays
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            print("[Audio] Session configured: playback/spokenAudio/duckOthers")
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
            // Emotional intro
            "opening_1", "opening_2",
            // Department selection
            "choose_department", "choose_industry",
            // Department input
            "department_input", "personal_input",
            // Building tension (department-specific)
            "building_p2p", "building_o2c", "building_customer_support", "building_itsm",
            "building_finance", "building_supply", "building_health",  // Legacy
            // Vignettes (department-specific)
            "vignette_p2p_enhanced", "vignette_o2c_enhanced", "vignette_customer_support_enhanced", "vignette_itsm_enhanced",
            "vignette_finance_enhanced", "vignette_supply_enhanced", "vignette_health_enhanced",  // Legacy
            // Pattern break & sucker punch
            "pattern_break_enhanced",
            "sucker_punch_reveal",  // General (no specific numbers)
            "sucker_punch_finance", "sucker_punch_supply", "sucker_punch_health",  // Legacy
            // Cost breakdown
            "cost_breakdown",
            // Comparisons (department-specific)
            "comparison_p2p_1", "comparison_p2p_2", "comparison_p2p_3",
            "comparison_o2c_1", "comparison_o2c_2", "comparison_o2c_3",
            "comparison_customer_support_1", "comparison_customer_support_2", "comparison_customer_support_3",
            "comparison_itsm_1", "comparison_itsm_2", "comparison_itsm_3",
            "comparison_finance_1", "comparison_finance_2", "comparison_finance_3",  // Legacy
            "comparison_supply_1", "comparison_supply_2", "comparison_supply_3",
            "comparison_health_1", "comparison_health_2", "comparison_health_3",
            // Solution
            "agentic_enhanced", "aa_reveal_forrester", "aa_reveal_enhanced",
            // AA Value Proposition (department-specific)
            "aa_value_p2p", "aa_value_o2c", "aa_value_customer_support", "aa_value_itsm",
            // Human return
            "restoration_enhanced", "breathe", "purpose",
            // Final CTA
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

    /// Enhanced narration scripts for all phases - CLINICAL TONE
    /// EXPRESSIVE with proper pause formatting: "..." directly after words (no spaces before)
    /// REGENERATED Jan 2026 - Clinical, professional delivery with substance
    /// UPDATED for Department-based system (P2P, O2C, Customer Support, ITSM)
    /// KEY PRINCIPLE: Narrations are GENERAL - no specific numbers in audio, numbers shown VISUALLY
    private let narratorLines: [String: String] = [
        // Emotional Intro - Per Neeti's edit
        "opening_1": "Every organization carries a hidden cost. Repetitive work. Manual processes. Lost time. And it's costing more than most leaders realize.",
        "opening_2": "Most leaders never quantify it. Until now.",

        // Department Selection - Per Neeti's edit
        "choose_department": "Choose a department and we will illustrate with an example.",
        "choose_industry": "Choose a department and we will illustrate with an example.",

        // Department Input - Per Neeti's edit
        "department_input": "Input your parameters to use industry benchmarks and calculate potential hidden costs.",
        "personal_input": "Input your parameters to use industry benchmarks and calculate potential hidden costs.",

        // Building Tension - Department Specific - Clinical and factual
        "building_p2p": "Invoice processing. Every invoice requires matching... verification... approval. Your team executes this workflow thousands of times annually. Industry data reveals the true cost.",
        "building_o2c": "Order to cash. Every order requires processing... credit verification... invoicing... collection. Each step introduces latency. Industry data reveals the true cost.",
        "building_customer_support": "Customer support. Every ticket requires intake... lookup... resolution. The same inquiries, processed repeatedly. Industry data reveals the true cost.",
        "building_itsm": "IT service management. Every request requires triage... assignment... resolution. Password resets alone consume significant capacity. Industry data reveals the true cost.",
        "building_finance": "Finance operations. Every transaction requires entry... reconciliation... approval. Your team executes this workflow thousands of times annually. Industry data reveals the true cost.",
        "building_supply": "Supply chain operations. Every shipment requires tracking... updating... exception handling. Manual touchpoints at every stage. Industry data reveals the true cost.",
        "building_health": "Clinical administration. Every patient requires charting... authorization... documentation. Time diverted from patient care. Industry data reveals the true cost.",

        // Department Vignettes - Clinical observations
        "vignette_p2p_enhanced": "Invoices accumulating. Cash flow constrained. Teams consumed by manual processing.",
        "vignette_o2c_enhanced": "Orders queued. Revenue delayed. Collection cycles extending.",
        "vignette_customer_support_enhanced": "Tickets accumulating. Response times lengthening. Agents repeating the same resolutions.",
        "vignette_itsm_enhanced": "Requests pending. Users waiting. Technical staff consumed by routine tasks.",
        "vignette_finance_enhanced": "Transactions queued. Reconciliations pending. Analysts consumed by data entry.",
        "vignette_supply_enhanced": "Shipments tracked manually. Exceptions mounting. Visibility degrading.",
        "vignette_health_enhanced": "Documentation backlog. Authorizations pending. Clinical staff consumed by paperwork.",

        // Pattern Break - Clinical question
        "pattern_break_enhanced": "What is the true operational cost?",

        // Sucker Punch - Clinical statement
        "sucker_punch_reveal": "This... is your invisible cost. Annually. Exposed.",
        "sucker_punch_finance": "This is what manual operations cost you. Annually. Exposed.",
        "sucker_punch_supply": "This is what manual processes cost you. Annually. Exposed.",
        "sucker_punch_health": "This is what administrative burden costs you. Annually. Exposed.",

        // Cost Breakdown - Clinical explanation
        "cost_breakdown": "Direct labor costs. Overhead allocation. And the hidden factors... exceptions, rework, opportunity cost.",

        // Comparisons - P2P - Clinical statements
        "comparison_p2p_1": "Full-time employees allocated entirely to manual processing.",
        "comparison_p2p_2": "Budget capacity redirected from strategic initiatives.",
        "comparison_p2p_3": "Productive hours consumed by repetitive manual tasks.",

        // Comparisons - O2C - Clinical statements
        "comparison_o2c_1": "Revenue held in accounts receivable.",
        "comparison_o2c_2": "Working capital unavailable for operations.",
        "comparison_o2c_3": "Work weeks consumed by manual collection processes.",

        // Comparisons - Customer Support - Clinical statements
        "comparison_customer_support_1": "Agent capacity consumed by routine inquiries.",
        "comparison_customer_support_2": "Hours spent on questions automation could resolve.",
        "comparison_customer_support_3": "Customer wait time that erodes satisfaction.",

        // Comparisons - ITSM - Clinical statements
        "comparison_itsm_1": "Cost of password resets alone.",
        "comparison_itsm_2": "User productivity lost waiting for IT resolution.",
        "comparison_itsm_3": "Technical staff time consumed by tier-one tickets.",

        // Comparisons - Legacy Finance
        "comparison_finance_1": "Analyst capacity consumed by manual data entry.",
        "comparison_finance_2": "Budget equivalent redirected from growth initiatives.",
        "comparison_finance_3": "Productive hours lost to reconciliation tasks.",

        // Comparisons - Legacy Supply Chain
        "comparison_supply_1": "Positions unfilled due to budget constraints.",
        "comparison_supply_2": "Shipments delayed by manual processing.",
        "comparison_supply_3": "Margin erosion from operational inefficiency.",

        // Comparisons - Legacy Healthcare
        "comparison_health_1": "Clinical staff time consumed by documentation.",
        "comparison_health_2": "Patient encounters that could have occurred.",
        "comparison_health_3": "Care capacity lost to administrative burden.",

        // Solution - Clinical explanation
        "agentic_enhanced": "Now consider: automation that operates across your entire system. AI agents that identify work, execute processes, and resolve issues... before escalation.",
        "aa_reveal_forrester": "Automation Anywhere. Industry-leading ROI. Fastest payback in the category. Validated by Forrester Total Economic Impact.",
        "aa_reveal_enhanced": "Automation Anywhere.",

        // AA Value Proposition - Department Specific - Clinical benefits
        "aa_value_p2p": "Touchless invoice processing. Straight-through matching. Exception handling automated. Your team reallocated to strategic finance.",
        "aa_value_o2c": "Accelerated collections. Compressed cycle times. Cash flow optimized.",
        "aa_value_customer_support": "Faster resolution. Higher satisfaction. Agents focused on complex cases that require human judgment.",
        "aa_value_itsm": "Instant provisioning. Automated resolution. IT talent redirected to strategic initiatives.",

        // Human Return - Clinical outcome
        "restoration_enhanced": "Manual work... automated. Repetitive processes... eliminated. Capacity... restored.",
        "breathe": "This is what operational efficiency looks like.",
        "purpose": "Strategy instead of spreadsheets. Innovation instead of administration. Leading instead of processing.",

        // Final CTA - Per Neeti's edit
        "final_cta_enhanced": "Say no to invisible costs. The question is: what will you do with the capacity you recover?",
        "ready_change": "Ready to recover this capacity?"
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

        // Fallback for AA value proposition files (if not yet generated)
        // These fall back to the general AA reveal
        let aaValueFallbacks = [
            "aa_reveal_forrester": "aa_reveal_enhanced",
            "aa_value_p2p": "aa_reveal_enhanced",
            "aa_value_o2c": "aa_reveal_enhanced",
            "aa_value_customer_support": "aa_reveal_enhanced",
            "aa_value_itsm": "aa_reveal_enhanced"
        ]
        if let fallback = aaValueFallbacks[key] {
            filenamesToTry.append("narration_\(fallback)")
        }

        for filename in filenamesToTry {
            for format in formats {
                if let url = Bundle.main.url(forResource: filename, withExtension: format) {
                    do {
                        narrationPlayer?.stop()
                        narrationPlayer = try AVAudioPlayer(contentsOf: url)
                        narrationPlayer?.volume = narrationVolume
                        narrationPlayer?.pan = 0  // Center pan (non-spatial)
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

        let key = currentNarrationKey ?? "unknown"
        currentNarrationKey = nil

        print("[Audio] Narration completed: \(key)")

        // IMPORTANT: Call completion handler SYNCHRONOUSLY before setting isNarrationPlaying to false
        // This prevents a race condition where update() sees narration stopped but narrationComplete
        // is still false (because the async handler hadn't run yet)
        let handler = narrationCompletionHandler
        narrationCompletionHandler = nil
        handler?()

        // Set isNarrationPlaying to false AFTER the completion handler runs
        // This ensures viewModel.narrationComplete is set before update() can check the state
        isNarrationPlaying = false
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
        case .departmentSelection:
            // Ambient music should already be playing from intro
            if !isAmbientPlaying {
                playAmbientMusic()
            }
        case .departmentInput:
            playTransition()  // Subtle transition sound
        case .buildingTension:
            playTransition()
        case .departmentVignette:
            playTransition()
        case .patternBreak:
            playTensionTone()
        case .suckerPunchReveal:
            // Handled by view with precise timing
            break
        case .costBreakdown:
            playTransition()
        case .comparisonCarousel:
            playCardWhoosh()
        case .agenticOrchestration:
            transitionToUpbeatMusic()
            playReveal()
        case .automationAnywhereReveal:
            playReveal()
        case .aaValueProposition:
            playReveal()
        case .humanReturn:
            playReveal()
        case .callToAction:
            playCompletion()
        }
    }

    /// Calculate the minimum duration needed for a phase based on its narrations
    /// ULTRA-TIGHTENED - minimal buffers, no dead space
    /// Based on MEASURED audio durations from expressive regeneration (Jan 2026)
    /// UPDATED for Department-based system
    func getMinimumPhaseDuration(for phase: Tier1Phase, department: Department?) -> TimeInterval {
        let buffer: TimeInterval = 0.8 // Ultra-tight breathing room

        switch phase {
        case .waiting, .complete:
            return 0

        case .emotionalIntro:
            // opening_1 (2.9s) + opening_2 (2.3s) + visual spacing
            return 10.0

        case .departmentSelection:
            return getNarrationDuration(for: "choose_department") + buffer

        case .departmentInput:
            return getNarrationDuration(for: "department_input") + buffer

        case .buildingTension:
            guard let dept = department else { return 14.0 }
            let key = "building_\(dept.rawValue)"
            return getNarrationDuration(for: key) + buffer

        case .departmentVignette:
            guard let dept = department else { return 5.0 }
            let key = "vignette_\(dept.rawValue)_enhanced"
            return getNarrationDuration(for: key) + buffer + 1.5 // Extra for metrics

        case .patternBreak:
            return 0 // User-controlled

        case .suckerPunchReveal:
            return 0 // User-controlled

        case .costBreakdown:
            return 0 // User-controlled (review at own pace)

        case .comparisonCarousel:
            return 0 // User-controlled

        case .agenticOrchestration:
            let narrationDuration = getNarrationDuration(for: "agentic_enhanced")
            return max(11.0, narrationDuration + buffer)

        case .automationAnywhereReveal:
            // Sync phase duration directly with audio - logo/tagline animations are percentage-based
            let narrationDuration = getNarrationDuration(for: "aa_reveal_forrester")
            return narrationDuration + buffer  // Audio duration + small buffer for exit fade

        case .aaValueProposition:
            return 0 // User-controlled (review Forrester data)

        case .humanReturn:
            // Two narrations in sequence: restoration, then purpose
            let restoration = getNarrationDuration(for: "restoration_enhanced")
            let purpose = getNarrationDuration(for: "purpose")
            return restoration + purpose + 0.5 // Tight gap between

        case .callToAction:
            return 0 // User-controlled, but should wait for narration
        }
    }
}

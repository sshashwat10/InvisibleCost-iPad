import SwiftUI
import Combine

struct NarrativeView: View {
    @State private var viewModel = ExperienceViewModel()
    @State private var motionManager = MotionManager()
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var lastPhase: Tier1Phase = .waiting
    @State private var audioTriggered: Set<String> = []
    
    private let audioManager = AudioManager.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background Animation Layer
            Group {
                switch viewModel.currentPhase {
                case .waiting, .microColdOpen:
                    Color.black
                case .narratorFrame:
                    NarratorFrameAnimation(progress: viewModel.phaseProgress)
                        .environment(motionManager)
                case .humanVignettes:
                    HumanVignettesAnimation(progress: viewModel.phaseProgress)
                        .environment(motionManager)
                case .patternBreak:
                    PatternBreakView(progress: viewModel.phaseProgress)
                case .agenticOrchestration:
                    AgenticOrchestrationAnimation(progress: viewModel.phaseProgress)
                        .environment(motionManager)
                case .humanReturn:
                    HumanReturnAnimation(progress: viewModel.phaseProgress)
                case .personalization:
                    PersonalizationView(viewModel: viewModel)
                case .stillnessCTA, .complete:
                    FinalCTAView(progress: viewModel.phaseProgress, isComplete: viewModel.currentPhase == .complete)
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 2.0)))
            
            // Experience Start Button (Overlay for 'waiting' state)
            if viewModel.currentPhase == .waiting {
                VStack {
                    Text("The Invisible Cost")
                        .font(.custom("Outfit", size: 48).weight(.ultraLight))
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    Button(action: {
                        viewModel.startExperience()
                    }) {
                        Text("Begin Experience")
                            .font(.custom("Outfit", size: 17).weight(.medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Audio indicator (debug)
            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if audioManager.isNarrationPlaying {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .foregroundColor(.green)
                                Text("Speaking")
                                    .font(.custom("Outfit", size: 11).weight(.light))
                                    .foregroundColor(.green)
                            }
                        }
                        Text("Progress: \(Int(viewModel.phaseProgress * 100))%")
                            .font(.custom("Outfit", size: 11).weight(.light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding()
            #endif
        }
        .onReceive(timer) { _ in
            if viewModel.isExperienceActive {
                viewModel.update(deltaTime: 0.1)
                handlePhaseChange()
                handleProgressBasedAudio()
                handleHaptics()
            }
        }
        .onAppear {
            hapticGenerator.prepare()
        }
        .onDisappear {
            audioManager.stopAll()
        }
    }
    
    // MARK: - Phase Change Detection
    
    private func handlePhaseChange() {
        if viewModel.currentPhase != lastPhase {
            // Phase changed - stop any playing narration first
            audioManager.stopNarration()
            
            // Play transition sound (except for first phase)
            if lastPhase != .waiting {
                audioManager.playTransition()
            }
            
            // Reset audio triggers for new phase
            audioTriggered.removeAll()
            
            lastPhase = viewModel.currentPhase
        }
    }
    
    // MARK: - Progress-Based Audio (synced with visuals)
    
    private func handleProgressBasedAudio() {
        let progress = viewModel.phaseProgress
        let phase = viewModel.currentPhase
        
        switch phase {
        case .waiting:
            break
            
        case .microColdOpen:
            // Start ambient sounds immediately
            triggerOnce("ambient") {
                audioManager.playAmbientHum()
            }
            
        case .narratorFrame:
            // Phase duration: 17s - balanced pacing
            triggerAtProgress("opening_1", threshold: 0.05, progress: progress) {
                audioManager.playNarration(for: "opening_1")
            }
            triggerAtProgress("opening_2", threshold: 0.36, progress: progress) {
                audioManager.playNarration(for: "opening_2")
            }
            triggerAtProgress("opening_3", threshold: 0.68, progress: progress) {
                audioManager.playNarration(for: "opening_3")
            }
            
        case .humanVignettes:
            // Phase duration: 15s - 3 vignettes
            triggerOnce("vignette_transition") {
                audioManager.playTransition()
            }
            triggerAtProgress("vignette_finance", threshold: 0.06, progress: progress) {
                audioManager.playNarration(for: "vignette_finance")
            }
            triggerAtProgress("vignette_supply_sound", threshold: 0.35, progress: progress) {
                audioManager.playTransition()
            }
            triggerAtProgress("vignette_supply", threshold: 0.37, progress: progress) {
                audioManager.playNarration(for: "vignette_supply")
            }
            triggerAtProgress("vignette_health_sound", threshold: 0.68, progress: progress) {
                audioManager.playTransition()
            }
            triggerAtProgress("vignette_health", threshold: 0.70, progress: progress) {
                audioManager.playNarration(for: "vignette_health")
            }
            
        case .patternBreak:
            // Phase duration: 6s - pattern break beat
            triggerAtProgress("pattern_break", threshold: 0.25, progress: progress) {
                audioManager.playNarration(for: "pattern_break")
            }
            
        case .agenticOrchestration:
            // Phase duration: 24s - THE AWAKENING
            
            // 🎵 Music transition
            triggerOnce("music_transition") {
                audioManager.transitionToUpbeatMusic(crossfadeDuration: 1.2)
            }
            
            triggerOnce("reveal") {
                audioManager.playReveal()
            }
            
            // === NODES APPEARING (0-25%) ===
            triggerAtProgress("dot_01", threshold: 0.04, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_02", threshold: 0.08, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_03", threshold: 0.12, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_04", threshold: 0.16, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_05", threshold: 0.20, progress: progress) { audioManager.playDotAppear() }
            
            // === CONNECTIONS FORMING (25-50%) ===
            triggerAtProgress("line_01", threshold: 0.26, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_02", threshold: 0.32, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_03", threshold: 0.38, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_04", threshold: 0.44, progress: progress) { audioManager.playLineForming() }
            
            // === SYNC PULSES (50-65%) ===
            triggerAtProgress("pulse_1", threshold: 0.50, progress: progress) { audioManager.playSpherePulse() }
            triggerAtProgress("pulse_2", threshold: 0.56, progress: progress) { audioManager.playSpherePulse() }
            
            // === TEXT + NARRATION (65-100%) ===
            triggerAtProgress("agentic", threshold: 0.62, progress: progress) {
                audioManager.playNarration(for: "agentic")
            }
            
        case .humanReturn:
            // Phase duration: 18s - 3 narrations
            triggerAtProgress("return_reveal", threshold: 0.05, progress: progress) {
                audioManager.playReveal()
            }
            triggerAtProgress("restoration", threshold: 0.10, progress: progress) {
                audioManager.playNarration(for: "restoration")
            }
            triggerAtProgress("human_return", threshold: 0.32, progress: progress) {
                audioManager.playNarration(for: "human_return")
            }
            triggerAtProgress("potential", threshold: 0.58, progress: progress) {
                audioManager.playNarration(for: "potential")
            }
            
        case .personalization:
            // Phase duration: 14s - interactive slider
            triggerOnce("ui_feedback") {
                audioManager.playUIFeedback()
            }
            
        case .stillnessCTA:
            // Phase duration: 50s - final impact sequence
            triggerOnce("completion") {
                audioManager.playCompletion()
            }
            triggerAtProgress("vision", threshold: 0.02, progress: progress) {
                audioManager.playNarration(for: "vision")
            }
            triggerAtProgress("closing", threshold: 0.20, progress: progress) {
                audioManager.playNarration(for: "closing")
            }
            triggerAtProgress("proof", threshold: 0.46, progress: progress) {
                audioManager.playNarration(for: "proof")
            }
            triggerAtProgress("question", threshold: 0.60, progress: progress) {
                audioManager.playNarration(for: "question")
            }
            triggerAtProgress("final_cta", threshold: 0.80, progress: progress) {
                audioManager.playNarration(for: "final_cta")
            }
            // Music fadeout - starts earlier for smoother ending
            triggerAtProgress("music_fadeout", threshold: 0.65, progress: progress) {
                audioManager.fadeOutUpbeatMusic(duration: 15.0)
            }
            
        case .complete:
            break
        }
    }
    
    /// Trigger action once per phase
    private func triggerOnce(_ key: String, action: () -> Void) {
        guard !audioTriggered.contains(key) else { return }
        audioTriggered.insert(key)
        action()
    }
    
    /// Trigger action when progress crosses threshold (once per phase)
    private func triggerAtProgress(_ key: String, threshold: Double, progress: Double, action: @escaping () -> Void) {
        guard !audioTriggered.contains(key) else { return }
        if progress >= threshold {
            audioTriggered.insert(key)
            // Only play if not already narrating (prevents overlap)
            if !audioManager.isNarrationPlaying {
                action()
            } else {
                // Delay slightly and try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    action()
                }
            }
        }
    }
    
    // MARK: - Haptics
    
    private func handleHaptics() {
        let progress = viewModel.phaseProgress
        
        // Micro-Cold Open: Subtle tap
        if viewModel.currentPhase == .microColdOpen && progress > 0.1 && progress < 0.15 {
            hapticGenerator.impactOccurred(intensity: 0.4)
        }
        
        // Human Vignettes: Taps on each vignette transition
        if viewModel.currentPhase == .humanVignettes {
            if (progress > 0.33 && progress < 0.35) || (progress > 0.66 && progress < 0.68) {
                hapticGenerator.impactOccurred(intensity: 0.3)
            }
        }
        
        // Pattern Break: Strong tap on question reveal
        if viewModel.currentPhase == .patternBreak && progress > 0.25 && progress < 0.28 {
            hapticGenerator.impactOccurred(intensity: 0.8)
        }
        
        // Agentic Orchestration: Subtle pulses when sphere pulses
        if viewModel.currentPhase == .agenticOrchestration && progress > 0.5 {
            let pulsePhase = (progress * 10).truncatingRemainder(dividingBy: 1.0)
            if pulsePhase < 0.05 {
                hapticGenerator.impactOccurred(intensity: 0.2)
            }
        }
        
        // Human Return: Warm tap on restoration
        if viewModel.currentPhase == .humanReturn && progress > 0.15 && progress < 0.18 {
            hapticGenerator.impactOccurred(intensity: 0.6)
        }
        
        // Final CTA: Completion tap
        if viewModel.currentPhase == .stillnessCTA && progress > 0.05 && progress < 0.08 {
            hapticGenerator.impactOccurred(intensity: 0.5)
        }
    }
}

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
                        .font(.system(size: 48, weight: .light, design: .serif))
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    Button(action: {
                        viewModel.startExperience()
                    }) {
                        Text("Begin Experience")
                            .font(.headline)
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
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        Text("Progress: \(Int(viewModel.phaseProgress * 100))%")
                            .font(.caption2)
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
            // Phase duration: 25s (synced to 180s ambient)
            // Narrations timed to visual reveals
            triggerAtProgress("opening_1", threshold: 0.05, progress: progress) { // ~1.5s
                audioManager.playNarration(for: "opening_1")
            }
            triggerAtProgress("opening_2", threshold: 0.35, progress: progress) { // ~10.5s
                audioManager.playNarration(for: "opening_2")
            }
            triggerAtProgress("opening_3", threshold: 0.65, progress: progress) { // ~19.5s
                audioManager.playNarration(for: "opening_3")
            }
            
        case .humanVignettes:
            // Phase duration: 22s, 3 vignettes (synced to 180s ambient)
            triggerOnce("vignette_transition") {
                audioManager.playTransition()
            }
            triggerAtProgress("vignette_finance", threshold: 0.08, progress: progress) {
                audioManager.playNarration(for: "vignette_finance")
            }
            triggerAtProgress("vignette_supply_sound", threshold: 0.38, progress: progress) {
                audioManager.playTransition()
            }
            triggerAtProgress("vignette_supply", threshold: 0.40, progress: progress) {
                audioManager.playNarration(for: "vignette_supply")
            }
            triggerAtProgress("vignette_health_sound", threshold: 0.70, progress: progress) {
                audioManager.playTransition()
            }
            triggerAtProgress("vignette_health", threshold: 0.72, progress: progress) {
                audioManager.playNarration(for: "vignette_health")
            }
            
        case .patternBreak:
            // Phase duration: 10s (synced to 180s ambient)
            // Ambient music continues playing throughout
            triggerAtProgress("pattern_break", threshold: 0.30, progress: progress) { // ~3.6s
                audioManager.playNarration(for: "pattern_break")
            }
            
        case .agenticOrchestration:
            // Phase duration: 32s (synced to 180s ambient)
            // Animation phases: dots appear (0-25%), lines form (20-45%), pulse (40-60%), shrink (55-70%), text (60-75%)
            
            triggerOnce("reveal") {
                audioManager.playReveal()
            }
            
            // === DOTS APPEARING (0-25%) ===
            // Many crystalline pings as dots materialize across the sphere
            triggerAtProgress("dot_01", threshold: 0.02, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_02", threshold: 0.04, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_03", threshold: 0.06, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_04", threshold: 0.08, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_05", threshold: 0.10, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_06", threshold: 0.11, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_07", threshold: 0.13, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_08", threshold: 0.14, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_09", threshold: 0.16, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_10", threshold: 0.17, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_11", threshold: 0.19, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_12", threshold: 0.20, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_13", threshold: 0.22, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_14", threshold: 0.23, progress: progress) { audioManager.playDotAppear() }
            triggerAtProgress("dot_15", threshold: 0.25, progress: progress) { audioManager.playDotAppear() }
            
            // === LINES FORMING (20-45%) ===
            // More connection sounds as the network forms
            triggerAtProgress("line_01", threshold: 0.21, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_02", threshold: 0.24, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_03", threshold: 0.27, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_04", threshold: 0.29, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_05", threshold: 0.31, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_06", threshold: 0.34, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_07", threshold: 0.36, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_08", threshold: 0.38, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_09", threshold: 0.40, progress: progress) { audioManager.playLineForming() }
            triggerAtProgress("line_10", threshold: 0.42, progress: progress) { audioManager.playLineForming() }
            
            // === PULSING (40-60%) ===
            // Breathing pulses - the sphere comes alive
            triggerAtProgress("pulse_1", threshold: 0.44, progress: progress) { audioManager.playSpherePulse() }
            triggerAtProgress("pulse_2", threshold: 0.48, progress: progress) { audioManager.playSpherePulse() }
            triggerAtProgress("pulse_3", threshold: 0.52, progress: progress) { audioManager.playSpherePulse() }
            triggerAtProgress("pulse_4", threshold: 0.55, progress: progress) { audioManager.playSpherePulse() }
            
            // === SHRINKING (55-75%) ===
            // Elegant convergence sound
            triggerAtProgress("shrink", threshold: 0.58, progress: progress) {
                audioManager.playSphereShrink()
            }
            
            // === TEXT APPEARS (70-85%) ===
            // Narration when text appears - slightly later for sync
            triggerAtProgress("agentic", threshold: 0.72, progress: progress) {
                audioManager.playNarration(for: "agentic")
            }
            
        case .humanReturn:
            // Phase duration: 21s - 2 second gap after agentic orchestration (synced to 180s ambient)
            // Reveal sound at ~2s (12% of 17s)
            triggerAtProgress("return_reveal", threshold: 0.12, progress: progress) {
                audioManager.playReveal()
            }
            // "And just like that, the weight begins to lift" - after 2s gap
            triggerAtProgress("restoration", threshold: 0.18, progress: progress) {
                audioManager.playNarration(for: "restoration")
            }
            // "The noise fades... clarity returns..." - mid phase, as figure fully appears
            triggerAtProgress("human_return", threshold: 0.45, progress: progress) {
                audioManager.playNarration(for: "human_return")
            }
            
        case .personalization:
            // Phase duration: 25s - minimal audio (synced to 180s ambient)
            triggerOnce("ui_feedback") {
                audioManager.playUIFeedback()
            }
            
        case .stillnessCTA:
            // Phase duration: 36s - extended for full narration (synced to 180s ambient)
            triggerOnce("completion") {
                audioManager.playCompletion()
            }
            // "Imagine your brightest minds..." - starts early, runs ~10s
            triggerAtProgress("closing", threshold: 0.10, progress: progress) {
                audioManager.playNarration(for: "closing")
            }
            // "The invisible cost has been paid..." - powerful closer, runs ~8s
            triggerAtProgress("question", threshold: 0.45, progress: progress) {
                audioManager.playNarration(for: "question")
            }
            // Gentle fadeout after narration completes
            triggerAtProgress("ambient_fadeout", threshold: 0.80, progress: progress) {
                audioManager.fadeOutAmbient(duration: 5.0)
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

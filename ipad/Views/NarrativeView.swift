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
            // Phase duration: 30s
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
            // Phase duration: 25s, 3 vignettes
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
            // Phase duration: 12s
            triggerOnce("fadeout") {
                audioManager.fadeOutAmbient(duration: 1.5)
            }
            triggerAtProgress("pattern_break", threshold: 0.30, progress: progress) { // ~3.6s
                audioManager.playNarration(for: "pattern_break")
            }
            
        case .agenticOrchestration:
            // Phase duration: 35s
            triggerOnce("reveal") {
                audioManager.playReveal()
            }
            // Sphere forming sound at start
            triggerOnce("sphere_start") {
                audioManager.playSphereForming()
            }
            // Connection sounds as nodes connect (multiple triggers)
            triggerAtProgress("connect_1", threshold: 0.15, progress: progress) {
                audioManager.playConnection()
            }
            triggerAtProgress("connect_2", threshold: 0.25, progress: progress) {
                audioManager.playConnection()
            }
            triggerAtProgress("connect_3", threshold: 0.35, progress: progress) {
                audioManager.playConnection()
            }
            // Narration when text appears
            triggerAtProgress("agentic", threshold: 0.60, progress: progress) {
                audioManager.playNarration(for: "agentic")
            }
            
        case .humanReturn:
            // Phase duration: 25s
            triggerOnce("return_reveal") {
                audioManager.playReveal()
            }
            triggerAtProgress("restoration", threshold: 0.15, progress: progress) {
                audioManager.playNarration(for: "restoration")
            }
            triggerAtProgress("human_return", threshold: 0.45, progress: progress) {
                audioManager.playNarration(for: "human_return")
            }
            
        case .personalization:
            // Phase duration: 30s - minimal audio
            triggerOnce("ui_feedback") {
                audioManager.playUIFeedback()
            }
            
        case .stillnessCTA:
            // Phase duration: 25s
            triggerOnce("completion") {
                audioManager.playCompletion()
            }
            triggerAtProgress("closing", threshold: 0.10, progress: progress) { // ~2.5s
                audioManager.playNarration(for: "closing")
            }
            triggerAtProgress("question", threshold: 0.50, progress: progress) { // ~12.5s
                audioManager.playNarration(for: "question")
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
    private func triggerAtProgress(_ key: String, threshold: Double, progress: Double, action: () -> Void) {
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

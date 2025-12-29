import SwiftUI
import Combine

struct NarrativeView: View {
    @State private var viewModel = ExperienceViewModel()
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
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
                case .humanVignettes:
                    HumanVignettesAnimation(progress: viewModel.phaseProgress)
                case .patternBreak:
                    PatternBreakView(progress: viewModel.phaseProgress)
                case .agenticOrchestration:
                    AgenticOrchestrationAnimation(progress: viewModel.phaseProgress)
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
        }
        .onReceive(timer) { _ in
            if viewModel.isExperienceActive {
                viewModel.update(deltaTime: 0.1)
                handleHaptics()
                handleAudio()
            }
        }
        .onAppear {
            hapticGenerator.prepare()
        }
    }
    
    // MARK: - Audio (Spec-True)
    
    private func handleAudio() {
        // 0. Micro-Cold Open: Ambient tapping, typing, and notification hum
        if viewModel.currentPhase == .microColdOpen && viewModel.phaseElapsedTime >= 0.1 && viewModel.phaseElapsedTime < 0.2 {
            Tier1AudioManager.shared.playAmbientHum()
        }
        
        // 1. Narrator Frame: "Every organization carries a hidden cost. Most leaders never see it."
        if viewModel.currentPhase == .narratorFrame && viewModel.phaseElapsedTime >= 0.5 && viewModel.phaseElapsedTime < 0.6 {
            Tier1AudioManager.shared.playNarratorLine("opening_frame")
        }
        
        // 3. Pattern Break: Silence (Stop all audio)
        if viewModel.currentPhase == .patternBreak && viewModel.phaseElapsedTime >= 0.1 && viewModel.phaseElapsedTime < 0.2 {
            Tier1AudioManager.shared.stopAll()
        }
        
        // 7. Stillness + CTA: Narrator closing
        if viewModel.currentPhase == .stillnessCTA && viewModel.phaseElapsedTime >= 2.0 && viewModel.phaseElapsedTime < 2.1 {
            Tier1AudioManager.shared.playNarratorLine("closing_frame")
        }
    }
    
    // MARK: - Haptics (Spec-True)
    
    private func handleHaptics() {
        // 0. Micro-Cold Open: Single subtle haptic tap as audio begins
        if viewModel.currentPhase == .microColdOpen && viewModel.phaseElapsedTime >= 0.1 && viewModel.phaseElapsedTime < 0.2 {
            hapticGenerator.impactOccurred(intensity: 0.4)
        }
        
        // 2. Human Vignettes: Subtle haptic taps during notification overwhelm moments
        if viewModel.currentPhase == .humanVignettes {
            // Trigger haptics at specific "notification" points
            let cycle = viewModel.phaseElapsedTime.truncatingRemainder(dividingBy: 4.0)
            if cycle > 0.5 && cycle < 0.6 || cycle > 1.2 && cycle < 1.3 || cycle > 3.0 && cycle < 3.1 {
                hapticGenerator.impactOccurred(intensity: 0.3)
            }
        }
        
        // 3. Pattern Break: Single haptic tap on the question reveal
        if viewModel.currentPhase == .patternBreak && viewModel.phaseElapsedTime >= 1.5 && viewModel.phaseElapsedTime < 1.6 {
            hapticGenerator.impactOccurred(intensity: 0.8)
        }
    }
}


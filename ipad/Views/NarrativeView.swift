import SwiftUI
import Combine

// MARK: - Enhanced Narrative View
/// Main orchestrator for the enhanced Invisible Cost experience
/// Implements Neeti's feedback: agency, personalization, sucker punch moment

struct NarrativeView: View {
    @State private var viewModel = ExperienceViewModel()
    @State private var motionManager = MotionManager()
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var lastPhase: Tier1Phase = .waiting
    @State private var audioTriggered: Set<String> = []

    private let audioManager = AudioManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Phase-specific content
            phaseContent
                .transition(.opacity.animation(.easeInOut(duration: 1.5)))

            // Start button overlay
            if viewModel.currentPhase == .waiting {
                startScreen
            }
        }
        .onReceive(timer) { _ in
            if viewModel.isExperienceActive {
                viewModel.update(deltaTime: 0.1)
                handlePhaseChange()
                handleProgressBasedAudio()
            }
        }
        .onDisappear {
            audioManager.stopAll()
        }
    }

    // MARK: - Start Screen

    private var startScreen: some View {
        VStack {
            Text("The Invisible Cost")
                .font(.system(size: 48, design: .rounded).weight(.ultraLight))
                .foregroundColor(.white)
                .padding(.bottom, 20)

            Text("An interactive experience")
                .font(.system(size: 18, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 40)

            Button(action: {
                viewModel.startExperience()
            }) {
                Text("Begin Experience")
                    .font(.system(size: 17, design: .rounded).weight(.medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Phase Content Router

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.currentPhase {
        case .waiting, .complete:
            Color.black

        case .industrySelection:
            IndustrySelectionView(
                selectedIndustry: $viewModel.selectedIndustry,
                onSelection: { industry in
                    viewModel.selectIndustry(industry)
                }
            )

        case .buildingTension:
            if let industry = viewModel.selectedIndustry {
                BuildingTensionView(
                    industry: industry,
                    progress: viewModel.phaseProgress
                )
                .environment(motionManager)
            }

        case .industryVignette:
            if let industry = viewModel.selectedIndustry {
                IndustryVignetteView(
                    industry: industry,
                    progress: viewModel.phaseProgress
                )
                .environment(motionManager)
            }

        case .patternBreak:
            PatternBreakEnhancedView(
                progress: viewModel.phaseProgress,
                onContinue: {
                    viewModel.advanceToNextPhase()
                }
            )

        case .suckerPunchReveal:
            if let industry = viewModel.selectedIndustry {
                SuckerPunchRevealView(
                    industry: industry,
                    progress: viewModel.phaseProgress,
                    onContinue: {
                        viewModel.advanceToNextPhase()
                    }
                )
            }

        case .comparisonCarousel:
            if let industry = viewModel.selectedIndustry {
                ComparisonCarouselView(
                    industry: industry,
                    onComplete: {
                        viewModel.advanceToNextPhase()
                    }
                )
            }

        case .agenticOrchestration:
            AgenticOrchestrationEnhancedView(
                industry: viewModel.selectedIndustry,
                progress: viewModel.phaseProgress
            )
            .environment(motionManager)

        case .automationAnywhereReveal:
            AutomationAnywhereRevealAnimation(progress: viewModel.phaseProgress)

        case .humanReturn:
            HumanReturnEnhancedView(
                industry: viewModel.selectedIndustry,
                progress: viewModel.phaseProgress
            )

        case .callToAction:
            FinalCTAEnhancedView(
                industry: viewModel.selectedIndustry,
                progress: viewModel.phaseProgress,
                onComplete: {
                    viewModel.endExperience()
                }
            )
        }
    }

    // MARK: - Phase Change Detection

    private func handlePhaseChange() {
        if viewModel.currentPhase != lastPhase {
            audioManager.stopNarration()

            // Play phase-specific audio
            audioManager.playAudioForPhase(viewModel.currentPhase, industry: viewModel.selectedIndustry)

            // Reset triggers
            audioTriggered.removeAll()
            lastPhase = viewModel.currentPhase

            print("[Narrative] Phase: \(viewModel.currentPhase.displayName)")
        }
    }

    // MARK: - Progress-Based Audio Sync

    private func handleProgressBasedAudio() {
        let progress = viewModel.phaseProgress
        let phase = viewModel.currentPhase

        switch phase {
        case .industrySelection:
            triggerOnce("choose_industry") {
                audioManager.playNarration(for: "choose_industry")
            }

        case .buildingTension:
            if let industry = viewModel.selectedIndustry {
                let key = "building_\(industry.rawValue)"
                triggerAtProgress(key, threshold: 0.05, progress: progress) {
                    audioManager.playNarration(for: key)
                }
            }

        case .industryVignette:
            if let industry = viewModel.selectedIndustry {
                let key = "vignette_\(industry.rawValue)_enhanced"
                triggerAtProgress(key, threshold: 0.1, progress: progress) {
                    audioManager.playNarration(for: key)
                }
            }

        case .patternBreak:
            triggerAtProgress("pattern_break_enhanced", threshold: 0.3, progress: progress) {
                audioManager.playNarration(for: "pattern_break_enhanced")
            }

        case .suckerPunchReveal:
            // Audio handled by SuckerPunchRevealView for precise sync
            if let industry = viewModel.selectedIndustry {
                let key = "sucker_punch_\(industry.rawValue)"
                triggerAtProgress(key, threshold: 0.5, progress: progress) {
                    audioManager.playNarration(for: key)
                }
            }

        case .agenticOrchestration:
            triggerOnce("music_transition") {
                audioManager.transitionToUpbeatMusic(crossfadeDuration: 1.5)
            }
            triggerAtProgress("agentic_enhanced", threshold: 0.65, progress: progress) {
                audioManager.playNarration(for: "agentic_enhanced")
            }

        case .automationAnywhereReveal:
            triggerAtProgress("aa_reveal_enhanced", threshold: 0.10, progress: progress) {
                audioManager.playNarration(for: "aa_reveal_enhanced")
            }

        case .humanReturn:
            triggerAtProgress("restoration_enhanced", threshold: 0.10, progress: progress) {
                audioManager.playNarration(for: "restoration_enhanced")
            }
            triggerAtProgress("breathe", threshold: 0.35, progress: progress) {
                audioManager.playNarration(for: "breathe")
            }
            triggerAtProgress("purpose", threshold: 0.60, progress: progress) {
                audioManager.playNarration(for: "purpose")
            }

        case .callToAction:
            triggerOnce("completion") {
                audioManager.playCompletion()
            }
            triggerAtProgress("final_cta_enhanced", threshold: 0.05, progress: progress) {
                audioManager.playNarration(for: "final_cta_enhanced")
            }
            triggerAtProgress("music_fadeout", threshold: 0.60, progress: progress) {
                audioManager.fadeOutMusic(duration: 8.0)
            }

        default:
            break
        }
    }

    // MARK: - Audio Trigger Helpers

    private func triggerOnce(_ key: String, action: () -> Void) {
        guard !audioTriggered.contains(key) else { return }
        audioTriggered.insert(key)
        action()
    }

    private func triggerAtProgress(_ key: String, threshold: Double, progress: Double, action: @escaping () -> Void) {
        guard !audioTriggered.contains(key) else { return }
        if progress >= threshold {
            audioTriggered.insert(key)
            if !audioManager.isNarrationPlaying {
                action()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    action()
                }
            }
        }
    }
}

// MARK: - Supporting Enhanced Views

/// Enhanced Pattern Break with tap-to-continue
struct PatternBreakEnhancedView: View {
    let progress: Double
    let onContinue: () -> Void

    @State private var showText1 = false
    @State private var showText2 = false
    @State private var showTapIndicator = false

    var body: some View {
        ZStack {
            // White background
            LinearGradient(
                colors: [Color(white: 0.98), Color(white: 1.0), Color(white: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // "But what if..."
                Text("But what if...")
                    .font(.system(size: 44, design: .rounded).weight(.ultraLight))
                    .foregroundColor(.black)
                    .opacity(showText1 ? 1 : 0)
                    .offset(y: showText1 ? 0 : 25)

                // "...you could see the real number?"
                Text("you could see the real number?")
                    .font(.system(size: 44, design: .rounded).weight(.light))
                    .foregroundColor(.black)
                    .opacity(showText2 ? 1 : 0)
                    .offset(y: showText2 ? 0 : 25)
            }

            // Tap indicator
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.black.opacity(0.3))

                    Text("Tap to reveal")
                        .font(.system(size: 14, design: .rounded).weight(.light))
                        .foregroundColor(.black.opacity(0.3))
                }
                .opacity(showTapIndicator ? 1 : 0)
                .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            if showTapIndicator {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onContinue()
            }
        }
        .onAppear {
            // Animate text appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showText1 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showText2 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showTapIndicator = true
                }
            }
        }
    }
}

/// Building Tension View - Industry-specific tension building
struct BuildingTensionView: View {
    let industry: Industry
    let progress: Double
    @Environment(MotionManager.self) private var motion

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let theme = industry.theme
            let content = IndustryContent.buildingTensionText(for: industry)

            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [Color(red: 0.02, green: 0.02, blue: 0.06), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Animated particles
                Canvas { context, size in
                    for i in 0..<50 {
                        let seed = Double(i) * 1.618
                        let speed = 0.15 + progress * 0.3 // Speed up as tension builds
                        let x = (sin(time * speed + seed * 2) * 0.5 + 0.5) * size.width
                        let y = (cos(time * speed * 0.7 + seed * 1.5) * 0.5 + 0.5) * size.height
                        let pulse = sin(time * 2 + seed) * 0.5 + 0.5
                        let particleSize: CGFloat = 2 + CGFloat(pulse) * 3

                        context.fill(
                            Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                            with: .color(theme.primary.opacity(0.08 + pulse * 0.08))
                        )
                    }
                }

                // Vignette that darkens with progress (building tension)
                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.3 + progress * 0.4)],
                    center: .center,
                    startRadius: 200,
                    endRadius: 500
                )

                // Text content
                VStack(spacing: 30) {
                    // Line 1
                    Text(content.line1)
                        .font(.system(size: 32, design: .rounded).weight(.ultraLight))
                        .foregroundColor(.white)
                        .opacity(progress > 0.1 ? 1 : 0)
                        .offset(y: progress > 0.1 ? 0 : 20)

                    // Line 2
                    Text(content.line2)
                        .font(.system(size: 32, design: .rounded).weight(.light))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(progress > 0.35 ? 1 : 0)
                        .offset(y: progress > 0.35 ? 0 : 20)

                    // Teaser metric
                    if progress > 0.65 {
                        Text(content.teaser)
                            .font(.system(size: 20, design: .rounded).weight(.light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.accent, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(progress > 0.65 ? 1 : 0)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            }
            .animation(.easeOut(duration: 0.8), value: progress)
        }
    }
}

/// Industry Vignette View - Deep dive into industry pain
struct IndustryVignetteView: View {
    let industry: Industry
    let progress: Double
    @Environment(MotionManager.self) private var motion

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let theme = industry.theme
            let data = IndustryContent.vignetteData(for: industry)

            ZStack {
                // Animated gradient background
                Color.black
                    .overlay(
                        RadialGradient(
                            colors: [theme.glow.opacity(0.35), Color.black],
                            center: .center,
                            startRadius: 0,
                            endRadius: 450
                        )
                        .scaleEffect(1.0 + sin(time * 0.5) * 0.08)
                    )
                    .ignoresSafeArea()

                // Particle ring
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    for i in 0..<40 {
                        let angle = time * 0.25 + Double(i) * 0.4
                        let radius = 120.0 + Double(i) * 10 + sin(time + Double(i)) * 20
                        let x = center.x + CGFloat(cos(angle) * radius)
                        let y = center.y + CGFloat(sin(angle * 0.7) * radius * 0.6)
                        let pulse = sin(time * 1.8 + Double(i)) * 0.5 + 0.5
                        let particleSize: CGFloat = 2 + CGFloat(pulse) * 4

                        context.fill(
                            Circle().path(in: CGRect(x: x - particleSize/2, y: y - particleSize/2,
                                                     width: particleSize, height: particleSize)),
                            with: .color(theme.primary.opacity(0.2 + pulse * 0.2))
                        )
                    }
                }

                // Content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [theme.primary.opacity(0.5), theme.primary.opacity(0.0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 280, height: 280)
                            .scaleEffect(1.0 + sin(time * 1.5) * 0.12)
                            .blur(radius: 10)

                        Image(systemName: industry.icon)
                            .font(.system(size: 55, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [theme.accent, theme.primary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: theme.accent.opacity(0.8), radius: 15)
                            .scaleEffect(progress > 0.1 ? 1.0 : 0.4)
                            .opacity(progress > 0.05 ? 1.0 : 0.0)
                    }

                    // Title
                    Text(data.title)
                        .font(.system(size: 18, design: .rounded).weight(.medium))
                        .tracking(16)
                        .foregroundColor(theme.accent)
                        .opacity(progress > 0.15 ? 1.0 : 0.0)

                    // Subtitle
                    Text(data.subtitle)
                        .font(.system(size: 32, design: .rounded).weight(.ultraLight))
                        .italic()
                        .foregroundColor(.white)
                        .opacity(progress > 0.25 ? 1.0 : 0.0)

                    // Metrics
                    HStack(spacing: 20) {
                        ForEach(Array(data.metrics.enumerated()), id: \.offset) { index, metric in
                            VStack(spacing: 6) {
                                Text(metric.value)
                                    .font(.system(size: 24, design: .rounded).weight(.light))
                                    .foregroundColor(theme.accent)
                                Text(metric.label)
                                    .font(.system(size: 11, design: .rounded).weight(.light))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(theme.glow.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(theme.primary.opacity(0.35), lineWidth: 1.5)
                                    )
                            )
                            .opacity(progress > (0.35 + Double(index) * 0.1) ? 1.0 : 0.0)
                            .offset(y: progress > (0.35 + Double(index) * 0.1) ? 0 : 20)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

/// Enhanced Agentic Orchestration with industry colors
struct AgenticOrchestrationEnhancedView: View {
    let industry: Industry?
    let progress: Double
    @Environment(MotionManager.self) private var motion

    var body: some View {
        // Reuse existing animation but with industry theme
        AgenticOrchestrationAnimation(progress: progress)
            .environment(motion)
    }
}

/// Enhanced Human Return with industry context
struct HumanReturnEnhancedView: View {
    let industry: Industry?
    let progress: Double

    var body: some View {
        HumanReturnAnimation(progress: progress)
    }
}

/// Enhanced Final CTA
struct FinalCTAEnhancedView: View {
    let industry: Industry?
    let progress: Double
    let onComplete: () -> Void

    var body: some View {
        FinalCTAView(progress: progress, isComplete: false)
            .onTapGesture {
                onComplete()
            }
    }
}

// MARK: - Preview

#Preview {
    NarrativeView()
}

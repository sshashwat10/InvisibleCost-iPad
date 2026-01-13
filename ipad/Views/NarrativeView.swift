import SwiftUI
import Combine

// MARK: - Enhanced Narrative View
/// Main orchestrator for the enhanced Invisible Cost experience
/// Implements Neeti's feedback: agency, personalization, sucker punch moment
/// NOW WITH PROPER AUDIO SYNC - Phases wait for narration to complete

struct NarrativeView: View {
    @State private var viewModel = ExperienceViewModel()
    @State private var motionManager = MotionManager()
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var lastPhase: Tier1Phase = .waiting
    @State private var audioTriggered: Set<String> = []

    // Track narration state for UI elements
    @State private var narrationFinished: Bool = false
    @State private var humanReturnNarrationIndex: Int = 0

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

        case .personalInput:
            PersonalizationInputView(
                companyName: $viewModel.companyName,
                teamSize: $viewModel.teamSize,
                lostHoursPerWeek: $viewModel.lostHoursPerWeek,
                hourlyRate: $viewModel.hourlyRate,
                calculatedAnnualCost: viewModel.calculatedAnnualCost,
                narrationFinished: narrationFinished,
                onContinue: {
                    viewModel.advanceToNextPhase()
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
                narrationFinished: narrationFinished,
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
                    },
                    onCardChange: { audioKey in
                        print("[Narrative] Comparison card audio: \(audioKey)")
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
                narrationFinished: narrationFinished,
                onComplete: {
                    viewModel.endExperience()
                },
                onRestart: {
                    // FIXED: Reset all audio before restarting experience
                    // This ensures BGM and narration start fresh
                    audioManager.resetForRestart()
                    audioTriggered.removeAll()
                    narrationFinished = false
                    humanReturnNarrationIndex = 0

                    viewModel.reset()
                    viewModel.startExperience()
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

            // Reset triggers and state
            audioTriggered.removeAll()
            narrationFinished = false
            humanReturnNarrationIndex = 0
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
                audioManager.playNarration(for: "choose_industry") { [self] in
                    narrationFinished = true
                    viewModel.onNarrationComplete()
                }
            }

        case .personalInput:
            triggerOnce("personal_input") {
                audioManager.playNarration(for: "personal_input") { [self] in
                    narrationFinished = true
                    viewModel.onNarrationComplete()
                }
            }

        case .buildingTension:
            if let industry = viewModel.selectedIndustry {
                let key = "building_\(industry.rawValue)"
                triggerAtProgress(key, threshold: 0.05, progress: progress) {
                    audioManager.playNarration(for: key) { [self] in
                        narrationFinished = true
                        viewModel.onNarrationComplete()
                    }
                }
            }

        case .industryVignette:
            if let industry = viewModel.selectedIndustry {
                let key = "vignette_\(industry.rawValue)_enhanced"
                triggerAtProgress(key, threshold: 0.1, progress: progress) {
                    audioManager.playNarration(for: key) { [self] in
                        narrationFinished = true
                        viewModel.onNarrationComplete()
                    }
                }
            }

        case .patternBreak:
            triggerAtProgress("pattern_break_enhanced", threshold: 0.1, progress: progress) {
                audioManager.playNarration(for: "pattern_break_enhanced") { [self] in
                    narrationFinished = true
                    viewModel.onNarrationComplete()
                }
            }

        case .suckerPunchReveal:
            // Audio handled by SuckerPunchRevealView for precise sync with counter animation
            if let industry = viewModel.selectedIndustry {
                let key = "sucker_punch_\(industry.rawValue)"
                triggerAtProgress(key, threshold: 0.3, progress: progress) {
                    audioManager.playNarration(for: key) { [self] in
                        narrationFinished = true
                        viewModel.onNarrationComplete()
                    }
                }
            }

        case .agenticOrchestration:
            triggerOnce("music_transition") {
                audioManager.transitionToUpbeatMusic(crossfadeDuration: 1.5)
            }
            triggerAtProgress("agentic_enhanced", threshold: 0.55, progress: progress) {
                audioManager.playNarration(for: "agentic_enhanced") { [self] in
                    narrationFinished = true
                    viewModel.onNarrationComplete()
                }
            }

        case .automationAnywhereReveal:
            // Trigger audio earlier (at 0.05) to ensure it plays
            // The animation starts fading in logo at 0.05, so sync audio with that
            triggerAtProgress("aa_reveal_enhanced", threshold: 0.05, progress: progress) {
                print("[Narrative] Playing AA reveal audio at progress: \(progress)")
                audioManager.playNarration(for: "aa_reveal_enhanced") { [self] in
                    narrationFinished = true
                    viewModel.onNarrationComplete()
                }
            }

        case .humanReturn:
            // Sequential narrations for human return phase
            handleHumanReturnNarrations(progress: progress)

        case .callToAction:
            triggerOnce("completion") {
                audioManager.playCompletion()
            }
            triggerAtProgress("final_cta_enhanced", threshold: 0.08, progress: progress) {
                audioManager.playNarration(for: "final_cta_enhanced") { [self] in
                    narrationFinished = true
                    viewModel.onNarrationComplete()
                }
            }
            triggerAtProgress("music_fadeout", threshold: 0.60, progress: progress) {
                audioManager.fadeOutMusic(duration: 8.0)
            }

        default:
            break
        }
    }

    // MARK: - Human Return Narration Sequence

    private func handleHumanReturnNarrations(progress: Double) {
        // Three sequential narrations: restoration, breathe, purpose
        // Each one waits for the previous to finish

        let narrations = ["restoration_enhanced", "breathe", "purpose"]
        let thresholds = [0.08, 0.35, 0.60]

        for (index, key) in narrations.enumerated() {
            if humanReturnNarrationIndex == index {
                triggerAtProgress(key, threshold: thresholds[index], progress: progress) {
                    audioManager.playNarration(for: key) { [self] in
                        humanReturnNarrationIndex = index + 1
                        if index == narrations.count - 1 {
                            // Last narration finished
                            narrationFinished = true
                            viewModel.onNarrationComplete()
                        }
                    }
                }
                break // Only trigger one at a time
            }
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
            // Only play if no other narration is currently playing
            if !audioManager.isNarrationPlaying {
                action()
            } else {
                // Queue it for when current narration finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !audioManager.isNarrationPlaying {
                        action()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Enhanced Views

/// Enhanced Pattern Break with tap-to-continue that waits for narration
struct PatternBreakEnhancedView: View {
    let progress: Double
    let narrationFinished: Bool
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

            // Tap indicator - only show after narration finishes
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
                .opacity(showTapIndicator && narrationFinished ? 1 : 0)
                .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            // Only allow tap after narration completes
            if showTapIndicator && narrationFinished {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onContinue()
            }
        }
        .onAppear {
            // Animate text appearance synced with narration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showText1 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showText2 = true
                }
            }
            // Show tap indicator after text animation, but it won't be tappable until narration finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
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

/// Enhanced Final CTA with proper narration sync
/// FIXED: Removed EXPERIENCE button, fixed overlapping buttons
struct FinalCTAEnhancedView: View {
    let industry: Industry?
    let progress: Double
    let narrationFinished: Bool
    let onComplete: () -> Void
    let onRestart: () -> Void

    @State private var showContent = false
    @State private var showCTA = false

    // Colors matching FinalCTAView
    private let signalGold = Color(red: 0.95, green: 0.8, blue: 0.4)
    private let pureWhite = Color.white
    private let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.04)

    // Computed phases (matching FinalCTAView timing)
    private var pulsePhase: Double { min(1.0, progress / 0.20) }
    private var text1Phase: Double { min(1.0, max(0, (progress - 0.15) / 0.20)) }
    private var text2Phase: Double { min(1.0, max(0, (progress - 0.30) / 0.20)) }
    private var questionPhase: Double { min(1.0, max(0, (progress - 0.45) / 0.20)) }
    private var ctaPhase: Double { min(1.0, max(0, (progress - 0.60) / 0.25)) }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                let centerX = geo.size.width / 2
                let centerY = geo.size.height * 0.35

                ZStack {
                    // Background
                    voidBlack.ignoresSafeArea()

                    // Signal pulses (same as FinalCTAView)
                    signalLayer(centerX: centerX, centerY: centerY, time: time)

                    // Content (text + buttons)
                    VStack(spacing: 0) {
                        Spacer().frame(height: geo.size.height * 0.48)

                        // Text section
                        textSection

                        Spacer().frame(height: 50)

                        // CTA buttons - only show after narration and showCTA
                        if showCTA && narrationFinished && ctaPhase > 0 {
                            ctaButtons
                                .opacity(ctaPhase)
                                .offset(y: (1 - ctaPhase) * 20)
                                .transition(.opacity.combined(with: .offset(y: 20)))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 50)
                }
            }
            .drawingGroup()
        }
        .onAppear {
            // Show content after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showContent = true
                }
            }
            // Show CTA buttons after progress reaches a point
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showCTA = true
                }
            }
        }
    }

    // MARK: - Signal Layer (matches FinalCTAView)

    private func signalLayer(centerX: CGFloat, centerY: CGFloat, time: Double) -> some View {
        ZStack {
            // Pulse rings layer
            Canvas { context, _ in
                let center = CGPoint(x: centerX, y: centerY)

                // Pulse rings
                for ring in 0..<4 {
                    let ringDelay = Double(ring) * 0.25
                    let pulseT = fmod(time * 0.4 + ringDelay, 1.0)
                    let ringRadius = 60 + CGFloat(pulseT) * 200
                    let ringOpacity = (1 - pulseT) * pulsePhase * 0.3

                    var ringPath = Path()
                    ringPath.addEllipse(in: CGRect(x: center.x - ringRadius, y: center.y - ringRadius,
                                                   width: ringRadius * 2, height: ringRadius * 2))
                    context.stroke(ringPath, with: .color(signalGold.opacity(ringOpacity)), lineWidth: 1.5)
                }

                // Outer glow
                context.fill(
                    Circle().path(in: CGRect(x: center.x - 70, y: center.y - 70, width: 140, height: 140)),
                    with: .radialGradient(
                        Gradient(colors: [signalGold.opacity(0.4 * pulsePhase), .clear]),
                        center: center, startRadius: 50, endRadius: 70
                    )
                )
            }

            // Central solid circle with lighter cream color for AA logo visibility
            Circle()
                .fill(Color(red: 1.0, green: 0.97, blue: 0.9).opacity(pulsePhase))
                .frame(width: 100, height: 100)
                .position(x: centerX, y: centerY)

            // AA Logo in center - on top of circle
            if let aaImage = UIImage(named: "aa") ?? loadAAImage() {
                Image(uiImage: aaImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .position(x: centerX, y: centerY)
                    .opacity(pulsePhase)
            }
        }
    }

    // MARK: - Text Section

    @ViewBuilder
    private var textSection: some View {
        VStack(spacing: 24) {
            if text1Phase > 0 {
                Text("One decision.")
                    .font(.system(size: 28, design: .rounded).weight(.ultraLight))
                    .foregroundColor(pureWhite.opacity(0.9))
                    .opacity(text1Phase)
            }

            if text2Phase > 0 {
                Text("Infinite possibility.")
                    .font(.system(size: 34, design: .rounded).weight(.light))
                    .foregroundStyle(LinearGradient(colors: [signalGold, pureWhite], startPoint: .leading, endPoint: .trailing))
                    .opacity(text2Phase)
            }

            if questionPhase > 0 {
                Rectangle()
                    .fill(signalGold.opacity(0.3))
                    .frame(width: 60, height: 1)
                    .opacity(questionPhase)
                    .padding(.vertical, 8)

                Text("Where will you lead?")
                    .font(.system(size: 18, design: .rounded).weight(.light))
                    .foregroundColor(pureWhite.opacity(0.6))
                    .opacity(questionPhase)
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - CTA Buttons (RESTART and DEMO only - removed EXPERIENCE)

    @ViewBuilder
    private var ctaButtons: some View {
        HStack(spacing: 40) {
            // Restart Experience
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onRestart()
            }) {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(signalGold.opacity(0.8))

                    Text("RESTART")
                        .font(.system(size: 10, design: .rounded).weight(.medium))
                        .tracking(4)
                        .foregroundColor(signalGold.opacity(0.7))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(RoundedRectangle(cornerRadius: 16).stroke(signalGold.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Demo button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                print("[CTA] Live Demo requested")
                onComplete()
            }) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(signalGold.opacity(0.5), lineWidth: 1)
                            .frame(width: 44, height: 44)

                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(signalGold)
                    }

                    Text("DEMO")
                        .font(.system(size: 10, design: .rounded).weight(.medium))
                        .tracking(4)
                        .foregroundColor(signalGold.opacity(0.8))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(RoundedRectangle(cornerRadius: 16).stroke(signalGold.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // Helper to load AA image from bundle
    private func loadAAImage() -> UIImage? {
        let extensions = ["jpg", "jpeg", "png"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: "aa", ofType: ext),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }
}

// MARK: - Personalization Input View (NEW for Davos 2026)
/// User inputs team size, hours lost, and hourly rate to see THEIR invisible cost

struct PersonalizationInputView: View {
    @Binding var companyName: String
    @Binding var teamSize: Double
    @Binding var lostHoursPerWeek: Double
    @Binding var hourlyRate: Double
    let calculatedAnnualCost: Double
    let narrationFinished: Bool
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showContinueButton = false

    // Team size presets (as Doubles for binding compatibility)
    private let teamSizePresets: [Double] = [50, 100, 250, 500, 1000]

    // Hourly rate presets (as Doubles for binding compatibility)
    private let hourlyRatePresets: [Double] = [75, 100, 150, 200]

    // Colors
    private let accentBlue = Color(red: 0.3, green: 0.5, blue: 1.0)
    private let glowBlue = Color(red: 0.4, green: 0.6, blue: 1.0)

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background
                backgroundView(time: time)

                // Content
                VStack(spacing: 35) {
                    // Title
                    titleSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Main input card
                    inputCard(time: time)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)

                    // Continue button (only after narration)
                    if showContinueButton && narrationFinished {
                        continueButton
                            .transition(.opacity.combined(with: .offset(y: 20)))
                    }
                }
                .padding(.horizontal, 60)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    showContent = true
                }
                // Show continue button after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showContinueButton = true
                    }
                }
            }
        }
    }

    // MARK: - Background

    private func backgroundView(time: Double) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Animated gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentBlue.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 700, height: 700)
                .offset(x: sin(time * 0.2) * 80, y: cos(time * 0.15) * 40 - 50)
                .blur(radius: 80)

            // Floating particles
            Canvas { context, size in
                for i in 0..<40 {
                    let seed = Double(i) * 1.618
                    let x = (sin(time * 0.15 + seed * 2) * 0.5 + 0.5) * size.width
                    let y = (cos(time * 0.1 + seed * 1.5) * 0.5 + 0.5) * size.height
                    let pulse = sin(time * 1.5 + seed) * 0.5 + 0.5
                    let particleSize: CGFloat = 1.5 + CGFloat(pulse) * 2

                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                        with: .color(accentBlue.opacity(0.06 + pulse * 0.06))
                    )
                }
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("YOUR INVISIBLE COST")
                .font(.system(size: 14, design: .rounded).weight(.medium))
                .tracking(8)
                .foregroundColor(accentBlue)

            Text("Let's calculate your number")
                .font(.system(size: 32, design: .rounded).weight(.ultraLight))
                .foregroundColor(.white)
        }
    }

    // MARK: - Input Card

    private func inputCard(time: Double) -> some View {
        VStack(spacing: 30) {
            // Optional company name
            VStack(alignment: .leading, spacing: 8) {
                Text("COMPANY NAME (OPTIONAL)")
                    .font(.system(size: 11, design: .rounded).weight(.medium))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.4))

                TextField("", text: $companyName, prompt: Text("Your Company").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 18, design: .rounded).weight(.light))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }

            // Team size presets
            VStack(alignment: .leading, spacing: 12) {
                Text("TEAM SIZE")
                    .font(.system(size: 11, design: .rounded).weight(.medium))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.4))

                HStack(spacing: 12) {
                    ForEach(teamSizePresets, id: \.self) { size in
                        presetButton(
                            label: "\(Int(size))",
                            isSelected: teamSize == size,
                            action: { teamSize = size }
                        )
                    }
                }
            }

            // Hours lost slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("HOURS LOST PER WEEK")
                        .font(.system(size: 11, design: .rounded).weight(.medium))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.4))

                    Spacer()

                    Text("\(Int(lostHoursPerWeek)) hours")
                        .font(.system(size: 16, design: .rounded).weight(.light))
                        .foregroundColor(accentBlue)
                }

                CustomSlider(
                    value: $lostHoursPerWeek,
                    range: 5...40,
                    accentColor: accentBlue
                )
            }

            // Hourly rate presets
            VStack(alignment: .leading, spacing: 12) {
                Text("AVERAGE HOURLY RATE")
                    .font(.system(size: 11, design: .rounded).weight(.medium))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.4))

                HStack(spacing: 12) {
                    ForEach(hourlyRatePresets, id: \.self) { rate in
                        presetButton(
                            label: "$\(Int(rate))",
                            isSelected: hourlyRate == rate,
                            action: { hourlyRate = rate }
                        )
                    }
                }
            }

            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, accentBlue.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Live cost preview
            VStack(spacing: 8) {
                Text("YOUR ESTIMATED ANNUAL COST")
                    .font(.system(size: 11, design: .rounded).weight(.medium))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.4))

                ZStack {
                    // Glow
                    Text(formatCurrency(calculatedAnnualCost))
                        .font(.system(size: 48, design: .rounded).weight(.light))
                        .foregroundColor(accentBlue.opacity(0.3))
                        .blur(radius: 15)

                    // Main number
                    Text(formatCurrency(calculatedAnnualCost))
                        .font(.system(size: 48, design: .rounded).weight(.light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [glowBlue, accentBlue, Color(red: 1.0, green: 0.4, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accentBlue.opacity(0.5), radius: 15)
                        .contentTransition(.numericText())
                }
                .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.02)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.02))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [accentBlue.opacity(0.3), .white.opacity(0.1), accentBlue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .frame(maxWidth: 600)
    }

    // MARK: - Preset Button

    private func presetButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Text(label)
                .font(.system(size: 15, design: .rounded).weight(isSelected ? .medium : .light))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? accentBlue : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accentBlue : Color.white.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onContinue()
        }) {
            HStack(spacing: 12) {
                Text("See Your Impact")
                    .font(.system(size: 17, design: .rounded).weight(.medium))

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [glowBlue, accentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: accentBlue.opacity(0.4), radius: 15)
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    NarrativeView()
}

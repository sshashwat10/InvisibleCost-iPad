import SwiftUI

// MARK: - AA Value Proposition View
/// Sourced ROI/savings display from Forrester TEI Study
/// ALL claims are SOURCED - no unsourced numbers
/// Visual presentation of hard data with citations

struct AAValuePropositionView: View {
    let savingsProjection: SavingsProjection
    let department: Department
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showHeroStats = false
    @State private var showBenefits = false
    @State private var animatedROI: Double = 0
    @State private var animatedSavings: Double = 0
    @State private var hasStartedAudio = false

    private var theme: DepartmentTheme { department.theme }
    private let forresterOrange = Color(red: 0.96, green: 0.5, blue: 0.1)
    private let audioManager = AudioManager.shared

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let isCompact = geometry.size.height < 700

                ZStack {
                    // Background
                    backgroundView(time: time)

                    VStack(spacing: isCompact ? 8 : 14) {
                        // Title
                        titleSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        // Hero ROI stats (Forrester TEI)
                        if showHeroStats {
                            heroStatsSection(time: time, isCompact: isCompact)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // Department-specific benefits
                        if showBenefits {
                            benefitsSection
                                .transition(.opacity.combined(with: .offset(y: 30)))
                        }

                        // Your projected savings
                        if showBenefits {
                            projectedSavingsSection(time: time, isCompact: isCompact)
                                .transition(.opacity.combined(with: .offset(y: 30)))
                        }

                        // Forrester TEI citation
                        if showBenefits {
                            forresterCitation
                                .transition(.opacity)
                        }

                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .onAppear {
                    startAnimationSequence()
                }
            }
        }
    }

    // MARK: - Animation Sequence (Synced with Audio, Auto-Progress)

    private func startAnimationSequence() {
        // Play department-specific AA value narration
        guard !hasStartedAudio else { return }
        hasStartedAudio = true

        let audioKey = "aa_value_\(department.rawValue)"
        let audioDuration = audioManager.getNarrationDuration(for: audioKey)

        // Play narration with completion callback to auto-progress
        audioManager.playNarration(for: audioKey) { [self] in
            // Auto-progress to next phase after narration completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onContinue()
            }
        }

        // Calculate animation timings based on audio duration
        let heroDelay: TimeInterval = audioDuration * 0.15  // 15% into audio
        let benefitsDelay: TimeInterval = audioDuration * 0.4  // 40% into audio

        // Title appears immediately
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }

        // Hero stats appear synced with audio
        DispatchQueue.main.asyncAfter(deadline: .now() + heroDelay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showHeroStats = true
            }

            // Animate ROI counter
            animateCounter(to: savingsProjection.roi * 100, binding: $animatedROI, duration: 1.2)
        }

        // Benefits appear mid-narration
        DispatchQueue.main.asyncAfter(deadline: .now() + benefitsDelay) {
            withAnimation(.easeOut(duration: 0.6)) {
                showBenefits = true
            }

            // Animate savings counter
            animateCounter(to: savingsProjection.annualSavings, binding: $animatedSavings, duration: 1.5)
        }
    }

    private func animateCounter(to target: Double, binding: Binding<Double>, duration: Double) {
        let steps = 40
        let stepDuration = duration / Double(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    binding.wrappedValue = target * Double(i) / Double(steps)
                }
            }
        }
    }

    // MARK: - Background

    private func backgroundView(time: Double) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Animated gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [forresterOrange.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 450
                    )
                )
                .frame(width: 900, height: 900)
                .offset(x: sin(time * 0.1) * 60, y: -150)
                .blur(radius: 100)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.primary.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 700, height: 700)
                .offset(x: -200, y: 200)
                .blur(radius: 80)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            // AA Logo placeholder
            HStack(spacing: 10) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [forresterOrange, Color(red: 1.0, green: 0.6, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("AUTOMATION ANYWHERE")
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .tracking(3)
                    .foregroundColor(.white)
            }

            Text("Proven Results")
                .font(.system(size: 28, design: .rounded).weight(.ultraLight))
                .foregroundColor(.white)
        }
    }

    // MARK: - Hero Stats Section (Forrester TEI)

    private func heroStatsSection(time: Double, isCompact: Bool = false) -> some View {
        HStack(spacing: isCompact ? 20 : 30) {
            // ROI
            VStack(spacing: 2) {
                ZStack {
                    Text("\(Int(animatedROI))%")
                        .font(.system(size: isCompact ? 40 : 52, design: .rounded).weight(.light))
                        .foregroundColor(forresterOrange.opacity(0.3))
                        .blur(radius: 12)

                    Text("\(Int(animatedROI))%")
                        .font(.system(size: isCompact ? 40 : 52, design: .rounded).weight(.light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [forresterOrange, Color(red: 1.0, green: 0.6, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: forresterOrange.opacity(0.5), radius: 15)
                        .contentTransition(.numericText())
                }
                .scaleEffect(1.0 + CGFloat(sin(time * 1.5)) * 0.02)

                Text("ROI over 3 years")
                    .font(.system(size: isCompact ? 10 : 12, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1, height: isCompact ? 50 : 70)

            // Payback
            VStack(spacing: 2) {
                ZStack {
                    Text("<12")
                        .font(.system(size: isCompact ? 40 : 52, design: .rounded).weight(.light))
                        .foregroundColor(Color.green.opacity(0.3))
                        .blur(radius: 12)

                    Text("<12")
                        .font(.system(size: isCompact ? 40 : 52, design: .rounded).weight(.light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.9, blue: 0.5), Color(red: 0.1, green: 0.8, blue: 0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.green.opacity(0.5), radius: 15)
                }
                .scaleEffect(1.0 + CGFloat(sin(time * 1.5 + 1)) * 0.02)

                Text("months payback")
                    .font(.system(size: isCompact ? 10 : 12, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, isCompact ? 16 : 24)
        .padding(.horizontal, isCompact ? 28 : 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [forresterOrange.opacity(0.4), .white.opacity(0.1), Color.green.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 6) {
            Text("FOR \(department.displayName)")
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(2)
                .foregroundColor(theme.accent)

            HStack(spacing: 10) {
                ForEach(savingsProjection.keyBenefits) { benefit in
                    BenefitCardCompact(benefit: benefit, theme: theme)
                }
            }
        }
    }

    // MARK: - Projected Savings Section

    private func projectedSavingsSection(time: Double, isCompact: Bool = false) -> some View {
        VStack(spacing: isCompact ? 8 : 12) {
            Text("YOUR PROJECTED ANNUAL SAVINGS")
                .font(.system(size: isCompact ? 9 : 10, design: .rounded).weight(.medium))
                .tracking(3)
                .foregroundColor(.white.opacity(0.4))

            ZStack {
                Text(animatedSavings.formattedAsCurrency)
                    .font(.system(size: isCompact ? 32 : 40, design: .rounded).weight(.light))
                    .foregroundColor(Color.green.opacity(0.3))
                    .blur(radius: 15)

                Text(animatedSavings.formattedAsCurrency)
                    .font(.system(size: isCompact ? 32 : 40, design: .rounded).weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.9, blue: 0.5), Color(red: 0.1, green: 0.75, blue: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.green.opacity(0.5), radius: 15)
                    .contentTransition(.numericText())
            }
            .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.02)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text(savingsProjection.formattedHoursRecovered)
                        .font(.system(size: isCompact ? 15 : 18, design: .rounded).weight(.medium))
                        .foregroundColor(theme.accent)
                    Text("hours recovered")
                        .font(.system(size: isCompact ? 9 : 10, design: .rounded).weight(.light))
                        .foregroundColor(.white.opacity(0.5))
                }

                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 1, height: isCompact ? 24 : 30)

                VStack(spacing: 2) {
                    Text("\(savingsProjection.formattedFTEEquivalent) FTEs")
                        .font(.system(size: isCompact ? 15 : 18, design: .rounded).weight(.medium))
                        .foregroundColor(theme.accent)
                    Text("redeployed")
                        .font(.system(size: isCompact ? 9 : 10, design: .rounded).weight(.light))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.vertical, isCompact ? 10 : 16)
        .padding(.horizontal, isCompact ? 24 : 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Forrester Citation

    private var forresterCitation: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10))
                .foregroundColor(forresterOrange)

            Text("Forrester TEI Study · $13.2M benefits over 3 years")
                .font(.system(size: 9, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(forresterOrange.opacity(0.05))
        )
    }

}

// MARK: - Compact Benefit Card

struct BenefitCardCompact: View {
    let benefit: BenefitItem
    let theme: DepartmentTheme

    var body: some View {
        VStack(spacing: 4) {
            // Icon
            Image(systemName: benefit.icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accent, theme.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.accent.opacity(0.5), radius: 4)

            // Headline stat
            Text(benefit.headline)
                .font(.system(size: 18, design: .rounded).weight(.medium))
                .foregroundColor(.white)

            // Description
            Text(benefit.description)
                .font(.system(size: 9, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(1)

            // Source
            Text(benefit.source)
                .font(.system(size: 7, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.3))
                .italic()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.glow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Benefit Card

struct BenefitCard: View {
    let benefit: BenefitItem
    let theme: DepartmentTheme

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: benefit.icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accent, theme.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.accent.opacity(0.5), radius: 8)

            // Headline stat
            Text(benefit.headline)
                .font(.system(size: 32, design: .rounded).weight(.medium))
                .foregroundColor(.white)

            // Description
            Text(benefit.description)
                .font(.system(size: 12, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Source
            Text(benefit.source)
                .font(.system(size: 9, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.3))
                .italic()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.glow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    let projection = SavingsProjection(
        annualSavings: 1_800_000,
        threeYearSavings: 5_400_000,
        hoursRecovered: 12000,
        roi: 2.62,
        paybackMonths: 12,
        department: .p2p,
        primaryBenefit: "78-81% cost reduction",
        primarySource: "Ardent Partners 2024",
        keyBenefits: [
            BenefitItem(icon: "dollarsign.circle.fill", headline: "79%", description: "Cost reduction", source: "Ardent Partners"),
            BenefitItem(icon: "gauge.with.needle.fill", headline: "82%", description: "Faster processing", source: "Ardent Partners"),
            BenefitItem(icon: "arrow.down.circle.fill", headline: "59%", description: "Fewer exceptions", source: "Forrester")
        ],
        forresterData: ForresterTEIData(
            roi: 2.62,
            paybackMonths: 12,
            totalBenefitsThreeYear: 13_200_000,
            staffRedeploymentSavings: 8_300_000,
            complianceAuditSavings: 2_700_000,
            errorReductionSavings: 1_100_000,
            source: "Forrester TEI",
            sourceURL: ""
        )
    )

    return AAValuePropositionView(
        savingsProjection: projection,
        department: .p2p,
        onContinue: { }
    )
}

import SwiftUI

// MARK: - Cost Breakdown View
/// Visual breakdown of direct/indirect/invisible costs
/// Animated bar chart with counting animations
/// All specific numbers shown VISUALLY (not in audio)

struct CostBreakdownView: View {
    let costBreakdown: CostBreakdown
    let department: Department
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showBars = false
    @State private var showDetails = false
    @State private var directProgress: CGFloat = 0
    @State private var indirectProgress: CGFloat = 0
    @State private var invisibleProgress: CGFloat = 0
    @State private var animatedDirectCost: Double = 0
    @State private var animatedIndirectCost: Double = 0
    @State private var animatedInvisibleCost: Double = 0

    private var theme: DepartmentTheme { department.theme }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background
                backgroundView(time: time)

                // Content - no scrolling, fit on screen
                VStack(spacing: 20) {
                    // Title
                    titleSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Main cost breakdown
                    breakdownSection(time: time)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)

                    // Key metrics
                    if showDetails {
                        keyMetricsSection
                            .transition(.opacity.combined(with: .offset(y: 20)))
                    }

                    // Source citation
                    if showDetails {
                        sourceSection
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }

                    Spacer()

                    // Continue button
                    if showDetails {
                        continueButton
                            .transition(.opacity.combined(with: .offset(y: 20)))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .onAppear {
                startAnimationSequence()
            }
        }
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Show content
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }

        // Show bars after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showBars = true
            }

            // Animate bars sequentially
            animateBarWithCounting(
                progress: $directProgress,
                animatedValue: $animatedDirectCost,
                targetValue: costBreakdown.directCost,
                delay: 0.2,
                duration: 1.2
            )

            animateBarWithCounting(
                progress: $indirectProgress,
                animatedValue: $animatedIndirectCost,
                targetValue: costBreakdown.indirectCost,
                delay: 0.6,
                duration: 1.2
            )

            animateBarWithCounting(
                progress: $invisibleProgress,
                animatedValue: $animatedInvisibleCost,
                targetValue: costBreakdown.invisibleCost,
                delay: 1.0,
                duration: 1.2
            )

            // Show details after bars animate
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showDetails = true
                }
            }
        }
    }

    private func animateBarWithCounting(
        progress: Binding<CGFloat>,
        animatedValue: Binding<Double>,
        targetValue: Double,
        delay: Double,
        duration: Double
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: duration)) {
                progress.wrappedValue = 1.0
            }

            // Counting animation
            let steps = 30
            let stepDuration = duration / Double(steps)
            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                    animatedValue.wrappedValue = targetValue * Double(i) / Double(steps)
                }
            }
        }
    }

    // MARK: - Background

    private func backgroundView(time: Double) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Gradient orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.primary.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 800, height: 800)
                .offset(x: sin(time * 0.1) * 50, y: -100)
                .blur(radius: 100)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("COST BREAKDOWN")
                .font(.system(size: 14, design: .rounded).weight(.medium))
                .tracking(8)
                .foregroundColor(theme.accent)

            Text("Where your invisible cost hides")
                .font(.system(size: 32, design: .rounded).weight(.ultraLight))
                .foregroundColor(.white)
        }
    }

    // MARK: - Breakdown Section

    private func breakdownSection(time: Double) -> some View {
        VStack(spacing: 20) {
            // Total cost (hero number)
            totalCostHero(time: time)

            // Cost bars
            VStack(spacing: 14) {
                CostBarCompact(
                    label: "Direct Labor",
                    value: animatedDirectCost,
                    totalValue: costBreakdown.totalCost,
                    progress: directProgress,
                    color: Color(red: 0.4, green: 0.7, blue: 1.0),
                    icon: "person.fill"
                )

                CostBarCompact(
                    label: "Overhead & Loaded",
                    value: animatedIndirectCost,
                    totalValue: costBreakdown.totalCost,
                    progress: indirectProgress,
                    color: Color(red: 0.9, green: 0.7, blue: 0.3),
                    icon: "building.2.fill"
                )

                CostBarCompact(
                    label: "Invisible Cost",
                    value: animatedInvisibleCost,
                    totalValue: costBreakdown.totalCost,
                    progress: invisibleProgress,
                    color: Color(red: 1.0, green: 0.4, blue: 0.4),
                    icon: "eye.slash.fill"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .frame(maxWidth: 600)
    }

    private func totalCostHero(time: Double) -> some View {
        VStack(spacing: 4) {
            Text("TOTAL INVISIBLE COST")
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(3)
                .foregroundColor(.white.opacity(0.4))

            ZStack {
                // Glow
                Text(costBreakdown.formattedTotalCost)
                    .font(.system(size: 38, design: .rounded).weight(.light))
                    .foregroundColor(Color.red.opacity(0.4))
                    .blur(radius: 15)

                // Main text
                Text(costBreakdown.formattedTotalCost)
                    .font(.system(size: 38, design: .rounded).weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color(red: 1.0, green: 0.3, blue: 0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.red.opacity(0.5), radius: 15)
            }
            .scaleEffect(1.0 + CGFloat(sin(time * 1.5)) * 0.02)

            Text("per year")
                .font(.system(size: 12, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Key Metrics Section

    private var keyMetricsSection: some View {
        HStack(spacing: 16) {
            ForEach(costBreakdown.keyMetrics, id: \.label) { metric in
                KeyMetricCardCompact(metric: metric, theme: theme)
            }
        }
        .frame(maxWidth: 600)
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))

            Text("Source: \(costBreakdown.benchmarkSource)")
                .font(.system(size: 10, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onContinue()
        }) {
            HStack(spacing: 10) {
                Text("See the Impact")
                    .font(.system(size: 15, design: .rounded).weight(.medium))

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: theme.primary.opacity(0.4), radius: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cost Bar Component

struct CostBar: View {
    let label: String
    let value: Double
    let totalValue: Double
    let progress: CGFloat
    let color: Color
    let icon: String
    let description: String

    private var percentage: CGFloat {
        guard totalValue > 0 else { return 0 }
        return CGFloat(value / totalValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label and value
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)

                    Text(label)
                        .font(.system(size: 14, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Text(value.formattedAsCurrency)
                    .font(.system(size: 16, design: .rounded).weight(.semibold))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * percentage * progress)

                    // Glow
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * percentage * progress)
                        .blur(radius: 6)
                        .opacity(0.4)
                }
            }
            .frame(height: 12)

            // Description
            Text(description)
                .font(.system(size: 11, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Key Metric Card

struct KeyMetricCard: View {
    let metric: KeyMetric
    let theme: DepartmentTheme

    var body: some View {
        VStack(spacing: 6) {
            Text(metric.value)
                .font(.system(size: 22, design: .rounded).weight(.medium))
                .foregroundColor(theme.accent)

            Text(metric.label)
                .font(.system(size: 11, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.glow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Cost Bar Component

struct CostBarCompact: View {
    let label: String
    let value: Double
    let totalValue: Double
    let progress: CGFloat
    let color: Color
    let icon: String

    private var percentage: CGFloat {
        guard totalValue > 0 else { return 0 }
        return CGFloat(value / totalValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(color)

                    Text(label)
                        .font(.system(size: 11, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Text(value.formattedAsCurrency)
                    .font(.system(size: 12, design: .rounded).weight(.semibold))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * percentage * progress)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * percentage * progress)
                        .blur(radius: 4)
                        .opacity(0.4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Compact Key Metric Card

struct KeyMetricCardCompact: View {
    let metric: KeyMetric
    let theme: DepartmentTheme

    var body: some View {
        VStack(spacing: 3) {
            Text(metric.value)
                .font(.system(size: 16, design: .rounded).weight(.medium))
                .foregroundColor(theme.accent)

            Text(metric.label)
                .font(.system(size: 9, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.glow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    let breakdown = CostBreakdown(
        annualHours: 15000,
        directCost: 1_125_000,
        indirectCost: 843_750,
        invisibleCost: 562_500,
        totalCost: 2_531_250,
        department: .p2p,
        benchmarkSource: "Ardent Partners 2024",
        keyMetrics: [
            KeyMetric(label: "Invoices/Year", value: "60,000"),
            KeyMetric(label: "Hours Lost", value: "15,000"),
            KeyMetric(label: "Exception Rate", value: "22%")
        ]
    )

    return CostBreakdownView(
        costBreakdown: breakdown,
        department: .p2p,
        onContinue: { }
    )
}

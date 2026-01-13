import SwiftUI

// MARK: - Sucker Punch Reveal View
/// THE MOMENT - Devastating cost reveal with maximum visual impact
/// Uses dramatic counter animation, glowing numbers, and comparison carousel

struct SuckerPunchRevealView: View {
    let industry: Industry
    let progress: Double
    let onContinue: () -> Void

    @State private var displayValue: Int = 0
    @State private var countingComplete = false
    @State private var showTagline = false
    @State private var numberGlowIntensity: CGFloat = 0

    private let suckerPunchData: SuckerPunchData

    init(industry: Industry, progress: Double, onContinue: @escaping () -> Void) {
        self.industry = industry
        self.progress = progress
        self.onContinue = onContinue
        self.suckerPunchData = IndustryContent.suckerPunchData(for: industry)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background
                backgroundView(time: time)

                VStack(spacing: 0) {
                    Spacer()

                    // Industry label
                    industryLabel
                        .opacity(progress > 0.05 ? 1 : 0)

                    Spacer().frame(height: 20)

                    // THE NUMBER
                    numberDisplay(time: time)

                    Spacer().frame(height: 30)

                    // "EVERY. SINGLE. YEAR."
                    taglineView
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 20)

                    Spacer()

                    // Continue prompt
                    continuePrompt
                        .opacity(countingComplete && progress > 0.7 ? 1 : 0)
                }
                .padding(.horizontal, 60)
            }
            .onAppear {
                startCountingAnimation()
            }
            .onTapGesture {
                if countingComplete {
                    onContinue()
                }
            }
        }
    }

    // MARK: - Background

    private func backgroundView(time: Double) -> some View {
        let theme = industry.theme

        return ZStack {
            // Deep black
            Color.black.ignoresSafeArea()

            // Dramatic radial glow behind number (pulses when complete)
            if countingComplete {
                RadialGradient(
                    colors: [
                        theme.primary.opacity(0.25 + sin(time * 2) * 0.1),
                        theme.glow.opacity(0.1),
                        .clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 400
                )
                .blur(radius: 60)
            }

            // Subtle particle field
            Canvas { context, size in
                for i in 0..<30 {
                    let seed = Double(i) * 1.618
                    let x = (sin(time * 0.1 + seed * 2) * 0.5 + 0.5) * size.width
                    let y = (cos(time * 0.08 + seed * 1.5) * 0.5 + 0.5) * size.height
                    let pulse = sin(time * 1.5 + seed) * 0.5 + 0.5
                    let particleSize: CGFloat = 1 + CGFloat(pulse) * 1.5

                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                        with: .color(theme.primary.opacity(0.03 + pulse * 0.03))
                    )
                }
            }
        }
    }

    // MARK: - Industry Label

    private var industryLabel: some View {
        let theme = industry.theme

        return VStack(spacing: 8) {
            Text("YOUR \(industry.displayName)'S")
                .font(.custom("Outfit", size: 12).weight(.medium))
                .tracking(6)
                .foregroundColor(theme.accent.opacity(0.7))

            Text("INVISIBLE COST")
                .font(.custom("Outfit", size: 16).weight(.light))
                .tracking(4)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - The Number Display

    private func numberDisplay(time: Double) -> some View {
        let theme = industry.theme

        // Format current display value with $ and commas
        let formattedValue = "$" + displayValue.formattedWithCommas

        return ZStack {
            // Outer glow layer (pulses when complete)
            if numberGlowIntensity > 0 {
                Text(formattedValue)
                    .font(.custom("Outfit", size: 120).weight(.light))
                    .foregroundColor(theme.primary.opacity(0.3))
                    .blur(radius: 40 * numberGlowIntensity)
            }

            // Middle glow layer
            if numberGlowIntensity > 0.3 {
                Text(formattedValue)
                    .font(.custom("Outfit", size: 120).weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent.opacity(0.4), Color.red.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blur(radius: 20)
            }

            // Main number with gradient
            Text(formattedValue)
                .font(.custom("Outfit", size: 120).weight(.light))
                .foregroundStyle(
                    LinearGradient(
                        colors: countingComplete
                            ? [theme.accent, .white, Color(red: 1.0, green: 0.4, blue: 0.3)]
                            : [.white.opacity(0.8), .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: countingComplete ? theme.primary.opacity(0.8) : .clear, radius: 20)
                .scaleEffect(countingComplete ? 1.0 + CGFloat(sin(time * 2)) * 0.02 : 1.0)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Tagline

    private var taglineView: some View {
        HStack(spacing: 20) {
            Text("EVERY.")
                .font(.custom("Outfit", size: 32).weight(.medium))
                .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.3))

            Text("SINGLE.")
                .font(.custom("Outfit", size: 32).weight(.medium))
                .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.3))

            Text("YEAR.")
                .font(.custom("Outfit", size: 32).weight(.medium))
                .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.3))
        }
        .shadow(color: Color.red.opacity(0.5), radius: 15)
    }

    // MARK: - Continue Prompt

    private var continuePrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.white.opacity(0.4))

            Text("Tap to continue")
                .font(.custom("Outfit", size: 14).weight(.light))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.bottom, 60)
    }

    // MARK: - Counting Animation

    private func startCountingAnimation() {
        let targetValue = suckerPunchData.amount
        let totalDuration: Double = 4.0
        let steps = 40
        let stepDuration = totalDuration / Double(steps)

        // Easing function for dramatic effect
        func easeOutExpo(_ t: Double) -> Double {
            return t == 1 ? 1 : 1 - pow(2, -10 * t)
        }

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(steps)
                let easedProgress = easeOutExpo(progress)

                withAnimation(.easeOut(duration: 0.05)) {
                    displayValue = Int(Double(targetValue) * easedProgress)
                }

                // Final step
                if i == steps {
                    displayValue = targetValue
                    countingComplete = true

                    // Haptic feedback on final number
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()

                    // Animate glow
                    withAnimation(.easeOut(duration: 0.5)) {
                        numberGlowIntensity = 1.0
                    }

                    // Show tagline after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showTagline = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Comparison Carousel View

struct ComparisonCarouselView: View {
    let industry: Industry
    let onComplete: () -> Void

    @State private var currentCardIndex = 0
    @State private var cardsShown = false

    private let comparisons: [ComparisonCard]
    private let theme: IndustryTheme

    init(industry: Industry, onComplete: @escaping () -> Void) {
        self.industry = industry
        self.onComplete = onComplete
        self.comparisons = IndustryContent.comparisonCards(for: industry)
        self.theme = industry.theme
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Ambient particles
                Canvas { context, size in
                    for i in 0..<25 {
                        let seed = Double(i) * 1.618
                        let x = (sin(time * 0.1 + seed * 2) * 0.5 + 0.5) * size.width
                        let y = (cos(time * 0.08 + seed * 1.5) * 0.5 + 0.5) * size.height
                        let pulse = sin(time * 1.5 + seed) * 0.5 + 0.5
                        let particleSize: CGFloat = 1 + CGFloat(pulse) * 1.5

                        context.fill(
                            Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                            with: .color(theme.primary.opacity(0.03 + pulse * 0.03))
                        )
                    }
                }

                VStack(spacing: 40) {
                    // Header with cost reminder
                    costHeader

                    Spacer()

                    // Current comparison card
                    if currentCardIndex < comparisons.count {
                        ComparisonCardView(
                            card: comparisons[currentCardIndex],
                            theme: theme,
                            time: time,
                            isActive: cardsShown
                        )
                        .id(currentCardIndex)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 50)),
                            removal: .opacity.combined(with: .offset(x: -50))
                        ))
                    } else {
                        // Final card - ready to continue
                        finalCard(time: time)
                    }

                    Spacer()

                    // Progress dots
                    progressDots

                    // Continue prompt
                    continuePrompt
                }
                .padding(.horizontal, 60)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    cardsShown = true
                }
            }
            .onTapGesture {
                advanceCard()
            }
        }
    }

    // MARK: - Cost Header

    private var costHeader: some View {
        let data = IndustryContent.suckerPunchData(for: industry)

        return VStack(spacing: 8) {
            Text(data.formattedAmount)
                .font(.custom("Outfit", size: 48).weight(.light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accent, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: theme.primary.opacity(0.5), radius: 10)

            Text("That's equivalent to...")
                .font(.custom("Outfit", size: 16).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 60)
    }

    // MARK: - Final Card

    private func finalCard(time: Double) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "arrow.right.circle")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accent, theme.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.05)

            Text("Ready to change this?")
                .font(.custom("Outfit", size: 28).weight(.light))
                .foregroundColor(.white)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(0.2))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.glow.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.accent.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 12) {
            ForEach(0..<(comparisons.count + 1), id: \.self) { index in
                Circle()
                    .fill(index <= currentCardIndex ? theme.accent : .white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentCardIndex ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentCardIndex)
            }
        }
    }

    // MARK: - Continue Prompt

    private var continuePrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: currentCardIndex >= comparisons.count ? "hand.tap" : "hand.tap")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.white.opacity(0.4))

            Text(currentCardIndex >= comparisons.count ? "Tap to see the solution" : "Tap for next")
                .font(.custom("Outfit", size: 13).weight(.light))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func advanceCard() {
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if currentCardIndex >= comparisons.count {
            onComplete()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentCardIndex += 1
            }
        }
    }
}

// MARK: - Comparison Card View

struct ComparisonCardView: View {
    let card: ComparisonCard
    let theme: IndustryTheme
    let time: Double
    let isActive: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                // Glow
                Image(systemName: card.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(theme.accent)
                    .blur(radius: 15)
                    .opacity(0.6)

                // Main
                Image(systemName: card.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent, theme.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(isActive ? 1.0 + CGFloat(sin(time * 1.5)) * 0.03 : 0.8)

            // Number (large)
            Text(card.number)
                .font(.custom("Outfit", size: 56).weight(.light))
                .foregroundColor(.white)

            // Unit
            Text(card.unit)
                .font(.custom("Outfit", size: 20).weight(.light))
                .foregroundColor(.white.opacity(0.6))

            // Emphasis
            Text(card.emphasis)
                .font(.custom("Outfit", size: 24).weight(.medium))
                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.35))
                .shadow(color: Color.red.opacity(0.4), radius: 8)
        }
        .padding(50)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [theme.glow.opacity(0.1), Color.black.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [theme.accent.opacity(0.4), theme.primary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isActive ? 1.0 : 0.9)
        .opacity(isActive ? 1.0 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Preview

#Preview("Sucker Punch - Finance") {
    SuckerPunchRevealView(
        industry: .finance,
        progress: 0.5,
        onContinue: {}
    )
}

#Preview("Comparison Carousel") {
    ComparisonCarouselView(
        industry: .finance,
        onComplete: {}
    )
}

import SwiftUI

// MARK: - Industry Selection View
/// Premium card selection interface for choosing industry vertical
/// Creates agency and personal investment from moment one

struct IndustrySelectionView: View {
    @Binding var selectedIndustry: Industry?
    let onSelection: (Industry) -> Void

    @State private var hoveredIndustry: Industry?
    @State private var cardsAppeared = false
    @State private var titleAppeared = false

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background with animated particles
                backgroundView(time: time)

                VStack(spacing: 60) {
                    // Title with fade-in
                    titleView
                        .opacity(titleAppeared ? 1 : 0)
                        .offset(y: titleAppeared ? 0 : -20)

                    // Industry cards
                    HStack(spacing: 40) {
                        ForEach(Array(Industry.allCases.enumerated()), id: \.element.id) { index, industry in
                            IndustryCardView(
                                industry: industry,
                                isHovered: hoveredIndustry == industry,
                                isSelected: selectedIndustry == industry,
                                appearDelay: Double(index) * 0.15,
                                hasAppeared: cardsAppeared,
                                time: time
                            )
                            .onTapGesture {
                                selectIndustry(industry)
                            }
                            .onHover { isHovered in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hoveredIndustry = isHovered ? industry : nil
                                }
                            }
                        }
                    }
                    .opacity(selectedIndustry == nil ? 1 : 0)

                    // Instruction text
                    instructionText
                        .opacity(titleAppeared && selectedIndustry == nil ? 1 : 0)
                }
            }
            .onAppear {
                animateEntrance()
            }
        }
    }

    // MARK: - Background

    private func backgroundView(time: Double) -> some View {
        ZStack {
            // Deep black base
            Color.black.ignoresSafeArea()

            // Animated ambient particles
            Canvas { context, size in
                for i in 0..<40 {
                    let seed = Double(i) * 1.618
                    let x = (sin(time * 0.08 + seed * 2) * 0.5 + 0.5) * size.width
                    let y = (cos(time * 0.06 + seed * 1.5) * 0.5 + 0.5) * size.height
                    let pulse = sin(time * 1.5 + seed) * 0.5 + 0.5
                    let particleSize: CGFloat = 1.5 + CGFloat(pulse) * 2

                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                        with: .color(Color.white.opacity(0.04 + pulse * 0.04))
                    )
                }
            }

            // Subtle vignette
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
        }
    }

    // MARK: - Title

    private var titleView: some View {
        VStack(spacing: 16) {
            Text("THE INVISIBLE COST")
                .font(.custom("Outfit", size: 14).weight(.medium))
                .tracking(8)
                .foregroundColor(.white.opacity(0.4))

            Text("Choose Your Industry")
                .font(.custom("Outfit", size: 42).weight(.ultraLight))
                .foregroundColor(.white)
        }
    }

    // MARK: - Instruction Text

    private var instructionText: some View {
        Text("Tap to see your invisible cost")
            .font(.custom("Outfit", size: 16).weight(.light))
            .foregroundColor(.white.opacity(0.4))
            .padding(.top, 20)
    }

    // MARK: - Actions

    private func selectIndustry(_ industry: Industry) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedIndustry = industry
        }

        // Delay callback for animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onSelection(industry)
        }
    }

    private func animateEntrance() {
        // Title appears first
        withAnimation(.easeOut(duration: 0.8)) {
            titleAppeared = true
        }

        // Cards appear after title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                cardsAppeared = true
            }
        }
    }
}

// MARK: - Industry Card View

struct IndustryCardView: View {
    let industry: Industry
    let isHovered: Bool
    let isSelected: Bool
    let appearDelay: Double
    let hasAppeared: Bool
    let time: Double

    // Animation state
    @State private var localAppeared = false

    private var scale: CGFloat {
        if isSelected { return 1.1 }
        if isHovered { return 1.05 }
        return 1.0
    }

    private var glowRadius: CGFloat {
        if isSelected { return 30 }
        if isHovered { return 20 }
        return 12
    }

    private var cardOpacity: Double {
        if !localAppeared { return 0 }
        if isSelected { return 1 }
        return 1
    }

    var body: some View {
        let theme = industry.theme

        ZStack {
            // Outer glow (animated)
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.primary.opacity(0.3))
                .blur(radius: glowRadius + CGFloat(sin(time * 2) * 3))
                .opacity(isHovered || isSelected ? 0.8 : 0.4)

            // Card background
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.glow.opacity(0.15),
                                    Color.black.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )

            // Card border
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(isHovered || isSelected ? 0.8 : 0.3),
                            theme.primary.opacity(isHovered || isSelected ? 0.5 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 2 : 1.5
                )

            // Card content
            VStack(spacing: 24) {
                // Icon with glow
                ZStack {
                    // Icon glow
                    Image(systemName: industry.icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(theme.accent)
                        .blur(radius: 15)
                        .opacity(0.6)

                    // Main icon
                    Image(systemName: industry.icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accent, theme.primary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: theme.primary.opacity(0.5), radius: 10)
                }
                .scaleEffect(1.0 + CGFloat(sin(time * 1.5)) * 0.03)

                // Industry name
                Text(industry.displayName)
                    .font(.custom("Outfit", size: 16).weight(.medium))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(40)
        }
        .frame(width: 220, height: 240)
        .scaleEffect(scale)
        .opacity(cardOpacity)
        .offset(y: localAppeared ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + appearDelay) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    localAppeared = hasAppeared
                }
            }
        }
        .onChange(of: hasAppeared) { _, newValue in
            if newValue && !localAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + appearDelay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        localAppeared = true
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    IndustrySelectionView(
        selectedIndustry: .constant(nil),
        onSelection: { _ in }
    )
}

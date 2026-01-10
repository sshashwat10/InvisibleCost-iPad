import SwiftUI

/// Text overlay for the Vision Pro narrative experience
/// Text COMPLEMENTS narration - never duplicates it
/// Uses Outfit font for 1:1 parity with iPad experience
struct NarrativeTextOverlay: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    
    // Custom font helper - falls back to system if Outfit not available
    private func outfitFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Try custom font first, fall back to system
        return .custom("Outfit", size: size).weight(weight)
    }
    
    var body: some View {
        ZStack {
            // Explicitly clear background
            Color.clear
            
            switch viewModel.currentPhase {
            case .waiting, .microColdOpen:
                EmptyView()
                
            case .narratorFrame:
                narratorFrameText
                
            case .spatialOverwhelm:
                sectorContent(
                    title: "FINANCE",
                    subtitle: "Reconciliation Fatigue",
                    metrics: [("4.7h", "daily reconciliation"), ("340", "manual entries"), ("23", "systems touched")],
                    primaryColor: Color(red: 0.3, green: 0.6, blue: 1.0),
                    glowColor: Color(red: 0.1, green: 0.3, blue: 0.7)
                )
                
            case .realityCrack:
                sectorContent(
                    title: "SUPPLY CHAIN",
                    subtitle: "Inventory Friction",
                    metrics: [("3.2h", "tracking overhead"), ("89%", "manual updates"), ("$2.4M", "annual waste")],
                    primaryColor: Color(red: 1.0, green: 0.7, blue: 0.3),
                    glowColor: Color(red: 0.7, green: 0.4, blue: 0.1)
                )
                
            case .humanFragment:
                sectorContent(
                    title: "HEALTHCARE",
                    subtitle: "Administrative Burden",
                    metrics: [("5.1h", "paperwork daily"), ("67%", "non-clinical"), ("142", "forms/week")],
                    primaryColor: Color(red: 0.3, green: 0.85, blue: 0.6),
                    glowColor: Color(red: 0.1, green: 0.5, blue: 0.3)
                )
                
            case .patternBreak:
                patternBreakText
                
            case .agenticOrchestration:
                agenticText
                
            case .humanReturn:
                humanReturnText
                
            case .personalization:
                personalizationText
                
            case .stillnessCTA:
                ctaText
                
            case .complete:
                completeText
            }
        }
        .background(.clear)
        .animation(.easeInOut(duration: 0.5), value: viewModel.currentPhase)
    }
    
    // MARK: - Narrator Frame (Visual only - narration handles words)
    // Matches iPad: Opening text + dramatic statistics
    
    private var narratorFrameText: some View {
        let progress = viewModel.phaseProgress
        
        return VStack(spacing: 35) {
            // Main opening text with dramatic glow (like iPad)
            if progress > 0.1 {
                ZStack {
                    Text("Every organization carries a hidden cost.")
                        .font(outfitFont(size: 32, weight: .light))
                        .foregroundStyle(.white.opacity(0.15))
                        .blur(radius: 15)
                    
                    Text("Every organization carries a hidden cost.")
                        .font(outfitFont(size: 32, weight: .light))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.3), radius: 12)
                }
                .opacity(progress > 0.1 ? 1 : 0)
                .offset(y: progress > 0.1 ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress > 0.1)
            }
            
            // Second line with red undertone
            if progress > 0.4 {
                ZStack {
                    Text("Most leaders never see it.")
                        .font(outfitFont(size: 32, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.25))
                        .blur(radius: 20)
                    
                    Text("Most leaders never see it.")
                        .font(outfitFont(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: Color.red.opacity(0.35), radius: 15)
                }
                .opacity(progress > 0.4 ? 1 : 0)
                .offset(y: progress > 0.4 ? 0 : 25)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress > 0.4)
            }
            
            // Statistics panel (like iPad)
            if progress > 0.7 {
                VStack(spacing: 20) {
                    // Decision count
                    HStack(spacing: 8) {
                        Text("You made")
                            .font(outfitFont(size: 18, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text("247")
                            .font(outfitFont(size: 24, weight: .light))
                            .foregroundStyle(.white)
                        
                        Text("decisions today.")
                            .font(outfitFont(size: 18, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    // Dramatic red stat
                    HStack(spacing: 8) {
                        Text("142")
                            .font(outfitFont(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.2, blue: 0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.red.opacity(0.5), radius: 15)
                        
                        Text("were unnecessary")
                            .font(outfitFont(size: 20, weight: .light))
                            .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
                    }
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.15))
                                .frame(width: 260, height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.4, blue: 0.3), Color(red: 1.0, green: 0.2, blue: 0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 260 * 0.575, height: 8)
                                .shadow(color: Color.red.opacity(0.5), radius: 6)
                        }
                        
                        Text("57% of your decisions could be automated")
                            .font(outfitFont(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(1)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)).combined(with: .offset(y: 15)))
            }
        }
        .animation(.easeOut(duration: 0.8), value: progress)
    }
    
    // MARK: - Sector Content (iPad Style with icon, title, subtitle, metrics)
    
    private func sectorContent(title: String, subtitle: String, metrics: [(String, String)], primaryColor: Color, glowColor: Color) -> some View {
        let progress = viewModel.phaseProgress
        
        return VStack(spacing: 28) {
            // Title with glow (Outfit font - matches iPad)
            if progress > 0.15 {
                ZStack {
                    Text(title)
                        .font(outfitFont(size: 18, weight: .heavy))
                        .tracking(12)
                        .foregroundStyle(primaryColor.opacity(0.4))
                        .blur(radius: 8)
                    
                    Text(title)
                        .font(outfitFont(size: 18, weight: .heavy))
                        .tracking(12)
                        .foregroundStyle(primaryColor)
                        .shadow(color: glowColor.opacity(0.6), radius: 12)
                }
                .transition(.opacity.combined(with: .offset(y: 15)))
            }
            
            // Subtitle - Outfit ultralight italic (matches iPad)
            if progress > 0.25 {
                ZStack {
                    Text(subtitle)
                        .font(outfitFont(size: 26, weight: .ultraLight))
                        .italic()
                        .foregroundStyle(.white.opacity(0.15))
                        .blur(radius: 12)
                    
                    Text(subtitle)
                        .font(outfitFont(size: 26, weight: .ultraLight))
                        .italic()
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .white.opacity(0.2), radius: 8)
                }
                .transition(.opacity.combined(with: .offset(y: 10)))
            }
            
            // Glass metric cards
            if progress > 0.35 {
                HStack(spacing: 16) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                        metricCard(value: metric.0, label: metric.1, color: primaryColor, glowColor: glowColor)
                            .opacity(progress > (0.35 + Double(index) * 0.08) ? 1 : 0)
                            .offset(y: progress > (0.35 + Double(index) * 0.08) ? 0 : 20)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
    }
    
    // MARK: - Metric Card (Glass morphism style)
    
    private func metricCard(value: String, label: String, color: Color, glowColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(outfitFont(size: 24, weight: .light))
                .foregroundStyle(color)
                .shadow(color: glowColor.opacity(0.4), radius: 6)
            
            Text(label)
                .font(outfitFont(size: 11, weight: .light))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(glowColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.35), lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Pattern Break (matches iPad)
    
    private var patternBreakText: some View {
        VStack(spacing: 15) {
            let progress = viewModel.phaseProgress
            
            if progress > 0.15 {
                Text("What if this work...")
                    .font(outfitFont(size: 44, weight: .ultraLight))
                    .foregroundStyle(.white)
                    .opacity(progress > 0.15 ? 1 : 0)
                    .offset(y: progress > 0.15 ? 0 : 25)
            }
            
            if progress > 0.35 {
                Text("wasn't your work?")
                    .font(outfitFont(size: 44, weight: .light))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.3), radius: 15)
                    .opacity(progress > 0.35 ? 1 : 0)
                    .offset(y: progress > 0.35 ? 0 : 25)
                    .scaleEffect(progress > 0.35 ? 1.0 : 0.95)
            }
        }
        .animation(.easeOut(duration: 1.0), value: viewModel.phaseProgress)
    }
    
    // MARK: - Agentic Orchestration (matches iPad - dramatic reveal)
    
    private var agenticText: some View {
        let progress = viewModel.phaseProgress
        // Text appears at 70% progress (after sphere has shrunk and positioned)
        let textPhase = min(1.0, max(0, (progress - 0.70) / 0.20))
        let taglinePhase = min(1.0, max(0, (textPhase - 0.3) / 0.7))
        
        // Colors matching iPad
        let coreGold = Color(red: 1.0, green: 0.85, blue: 0.4)
        let electricBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
        
        return VStack(spacing: 16) {
            if textPhase > 0 {
                // Dramatic title with multi-layer glow (matches iPad exactly)
                ZStack {
                    // Outer glow
                    Text("AGENTIC ORCHESTRATION")
                        .font(outfitFont(size: 28, weight: .medium))
                        .tracking(8)
                        .foregroundStyle(coreGold.opacity(0.3))
                        .blur(radius: 20)
                    
                    // Mid glow
                    Text("AGENTIC ORCHESTRATION")
                        .font(outfitFont(size: 28, weight: .medium))
                        .tracking(8)
                        .foregroundStyle(electricBlue.opacity(0.5))
                        .blur(radius: 10)
                    
                    // Main text with gradient
                    Text("AGENTIC ORCHESTRATION")
                        .font(outfitFont(size: 28, weight: .medium))
                        .tracking(8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [coreGold, .white, electricBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: coreGold.opacity(0.8), radius: 15)
                        .shadow(color: electricBlue.opacity(0.5), radius: 30)
                }
                .opacity(textPhase)
                .scaleEffect(0.95 + textPhase * 0.05)
                .offset(y: (1 - textPhase) * 20)
                
                // Tagline (matches iPad)
                if taglinePhase > 0 {
                    Text("Intelligence that orchestrates. Agents that deliver.")
                        .font(outfitFont(size: 14, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(taglinePhase)
                        .offset(y: (1 - taglinePhase) * 15)
                }
            }
        }
        .animation(.easeOut(duration: 0.8), value: progress > 0.70)
    }
    
    // MARK: - Human Return (matches iPad - staggered text reveal)
    
    private var humanReturnText: some View {
        let progress = viewModel.phaseProgress
        let accentBlue = Color(red: 0.0, green: 0.6, blue: 0.75)
        let glowBlue = Color(red: 0.1, green: 0.7, blue: 0.85)
        
        // Smoothstep phases matching iPad exactly
        let labelOpacity = min(1.0, max(0, (progress - 0.25) / 0.25))
        let titleOpacity = min(1.0, max(0, (progress - 0.35) / 0.25))
        let subtitleOpacity = min(1.0, max(0, (progress - 0.55) / 0.25))
        
        return VStack(spacing: 16) {
            // RESTORATION label
            if labelOpacity > 0 {
                Text("RESTORATION")
                    .font(outfitFont(size: 13, weight: .medium))
                    .tracking(10)
                    .foregroundStyle(accentBlue)
                    .opacity(labelOpacity)
                    .offset(y: (1 - labelOpacity) * 10)
            }
            
            // Main title
            if titleOpacity > 0 {
                Text("Human potential returned.")
                    .font(outfitFont(size: 32, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(titleOpacity)
                    .offset(y: (1 - titleOpacity) * 15)
            }
            
            // Subtitle
            if subtitleOpacity > 0 {
                Text("Reviewing insights. Approving paths.")
                    .font(outfitFont(size: 18, weight: .light))
                    .foregroundStyle(glowBlue)
                    .opacity(subtitleOpacity)
                    .offset(y: (1 - subtitleOpacity) * 10)
            }
        }
        .animation(.easeOut(duration: 0.6), value: progress)
    }
    
    // MARK: - Personalization (Animated Impact Reveal - matches iPad concept)
    // Shows animated counter revealing the invisible cost impact
    
    private var personalizationText: some View {
        let progress = viewModel.phaseProgress
        let accentBlue = Color(red: 0.3, green: 0.5, blue: 1.0)
        let glowBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
        
        // Animation phases
        let questionPhase = min(1.0, max(0, progress / 0.20))
        let hoursPhase = min(1.0, max(0, (progress - 0.15) / 0.25))
        let impactPhase = min(1.0, max(0, (progress - 0.40) / 0.30))
        let revealPhase = min(1.0, max(0, (progress - 0.70) / 0.30))
        
        // Animated hours (counts up from 0 to 20)
        let animatedHours = Int(hoursPhase * viewModel.lostHoursPerWeek)
        
        // Animated impact (counts up)
        let animatedImpact = viewModel.annualImpact * impactPhase
        
        return VStack(spacing: 30) {
            // Question text
            if questionPhase > 0 {
                ZStack {
                    Text("What is the invisible cost to your organization?")
                        .font(outfitFont(size: 26, weight: .ultraLight))
                        .foregroundStyle(accentBlue.opacity(0.25))
                        .blur(radius: 12)
                    
                    Text("What is the invisible cost to your organization?")
                        .font(outfitFont(size: 26, weight: .ultraLight))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.2), radius: 8)
                }
                .multilineTextAlignment(.center)
                .opacity(questionPhase)
                .offset(y: (1 - questionPhase) * 20)
            }
            
            // Hours display with animated counter
            if hoursPhase > 0 {
                VStack(spacing: 12) {
                    // Large animated number
                    ZStack {
                        Text("\(animatedHours)")
                            .font(outfitFont(size: 80, weight: .ultraLight))
                            .foregroundStyle(accentBlue.opacity(0.25))
                            .blur(radius: 18)
                        
                        Text("\(animatedHours)")
                            .font(outfitFont(size: 80, weight: .ultraLight))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [glowBlue, accentBlue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: accentBlue.opacity(0.5), radius: 18)
                    }
                    
                    Text("HOURS LOST PER WEEK")
                        .font(outfitFont(size: 13, weight: .medium))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .opacity(hoursPhase)
                .offset(y: (1 - hoursPhase) * 15)
            }
            
            // Divider
            if impactPhase > 0 {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, accentBlue.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 1)
                    .opacity(impactPhase)
            }
            
            // Impact reveal
            if impactPhase > 0 {
                HStack(spacing: 60) {
                    // Team size
                    VStack(spacing: 6) {
                        Text("\(Int(viewModel.teamSize))")
                            .font(outfitFont(size: 32, weight: .light))
                            .foregroundStyle(.white)
                        Text("TEAM SIZE")
                            .font(outfitFont(size: 11, weight: .medium))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // Annual impact (animated)
                    VStack(spacing: 6) {
                        ZStack {
                            Text("$\(formatNumber(animatedImpact))")
                                .font(outfitFont(size: 32, weight: .light))
                                .foregroundStyle(Color.green.opacity(0.3))
                                .blur(radius: 10)
                            
                            Text("$\(formatNumber(animatedImpact))")
                                .font(outfitFont(size: 32, weight: .light))
                                .foregroundStyle(Color.green)
                                .shadow(color: Color.green.opacity(0.5), radius: 12)
                        }
                        Text("ANNUAL IMPACT")
                            .font(outfitFont(size: 11, weight: .medium))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .opacity(impactPhase)
                .offset(y: (1 - impactPhase) * 15)
            }
            
            // Final dramatic reveal message
            if revealPhase > 0 {
                Text("This is the invisible cost.")
                    .font(outfitFont(size: 20, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.7), Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(revealPhase)
                    .offset(y: (1 - revealPhase) * 10)
            }
        }
        .animation(.easeOut(duration: 0.5), value: progress)
    }
    
    // MARK: - CTA (matches iPad - staggered pulse reveal)
    
    private var ctaText: some View {
        let progress = viewModel.phaseProgress
        let signalGold = Color(red: 0.95, green: 0.8, blue: 0.4)
        
        // Phases matching iPad exactly
        let text1Phase = min(1.0, max(0, (progress - 0.15) / 0.20))
        let text2Phase = min(1.0, max(0, (progress - 0.30) / 0.20))
        let questionPhase = min(1.0, max(0, (progress - 0.45) / 0.20))
        let ctaPhase = min(1.0, max(0, (progress - 0.60) / 0.25))
        
        return VStack(spacing: 24) {
            // Text 1: "One decision."
            if text1Phase > 0 {
                Text("One decision.")
                    .font(outfitFont(size: 28, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(text1Phase)
                    .offset(y: (1 - text1Phase) * 15)
            }
            
            // Text 2: "Infinite possibility."
            if text2Phase > 0 {
                Text("Infinite possibility.")
                    .font(outfitFont(size: 34, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [signalGold, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(text2Phase)
                    .offset(y: (1 - text2Phase) * 15)
            }
            
            // Decorative separator
            if questionPhase > 0 {
                Rectangle()
                    .fill(signalGold.opacity(0.3))
                    .frame(width: 60, height: 1)
                    .opacity(questionPhase)
                    .padding(.vertical, 8)
            }
            
            // Question text
            if questionPhase > 0 {
                Text("Where will you lead?")
                    .font(outfitFont(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(questionPhase)
                    .offset(y: (1 - questionPhase) * 15)
            }
            
            Spacer().frame(height: 40)
            
            // CTA section - Brand with dramatic reveal
            if ctaPhase > 0 {
                VStack(spacing: 20) {
                    // Logo/Brand with multi-layer glow (matches iPad)
                    ZStack {
                        Text("AUTOMATION ANYWHERE")
                            .font(outfitFont(size: 22, weight: .bold))
                            .tracking(6)
                            .foregroundStyle(signalGold.opacity(0.3))
                            .blur(radius: 15)
                        
                        Text("AUTOMATION ANYWHERE")
                            .font(outfitFont(size: 22, weight: .bold))
                            .tracking(6)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [signalGold, .white, signalGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: signalGold.opacity(0.6), radius: 20)
                    }
                }
                .opacity(ctaPhase)
                .scaleEffect(0.95 + ctaPhase * 0.05)
            }
        }
        .animation(.easeOut(duration: 0.6), value: progress)
    }
    
    // MARK: - Complete
    
    private var completeText: some View {
        Text("Experience Complete")
            .font(outfitFont(size: 28, weight: .light))
            .foregroundStyle(.white.opacity(0.7))
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}

#Preview {
    NarrativeTextOverlay()
        .environment(ExperienceViewModel())
        .preferredColorScheme(.dark)
}

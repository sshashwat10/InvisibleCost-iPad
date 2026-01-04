import SwiftUI

/// Text overlay for the Vision Pro narrative experience
/// Text COMPLEMENTS narration - never duplicates it
struct NarrativeTextOverlay: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    
    var body: some View {
        ZStack {
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
                EmptyView()
                
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
        .animation(.easeInOut(duration: 0.5), value: viewModel.currentPhase)
    }
    
    // MARK: - Narrator Frame (Visual only - narration handles words)
    
    private var narratorFrameText: some View {
        VStack(spacing: 20) {
            let progress = viewModel.phaseProgress
            
            if progress > 0.6 {
                VStack(spacing: 16) {
                    Text("142")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.2, blue: 0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.red.opacity(0.5), radius: 20)
                    
                    Text("unnecessary decisions today")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.8), value: viewModel.phaseProgress)
    }
    
    // MARK: - Sector Content (iPad Style with icon, title, subtitle, metrics)
    
    private func sectorContent(title: String, subtitle: String, metrics: [(String, String)], primaryColor: Color, glowColor: Color) -> some View {
        let progress = viewModel.phaseProgress
        
        return VStack(spacing: 28) {
            // Title with glow
            if progress > 0.15 {
                ZStack {
                    Text(title)
                        .font(.system(size: 18, weight: .black))
                        .tracking(12)
                        .foregroundStyle(primaryColor.opacity(0.4))
                        .blur(radius: 8)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .black))
                        .tracking(12)
                        .foregroundStyle(primaryColor)
                        .shadow(color: glowColor.opacity(0.6), radius: 12)
                }
                .transition(.opacity.combined(with: .offset(y: 15)))
            }
            
            // Subtitle (italic serif)
            if progress > 0.25 {
                ZStack {
                    Text(subtitle)
                        .font(.system(size: 26, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.15))
                        .blur(radius: 12)
                    
                    Text(subtitle)
                        .font(.system(size: 26, weight: .light, design: .serif))
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
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: glowColor.opacity(0.4), radius: 6)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
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
    
    // MARK: - Agentic Orchestration
    
    private var agenticText: some View {
        VStack(spacing: 16) {
            if viewModel.phaseProgress > 0.70 {
                // Epic title only - narration explains
                ZStack {
                    Text("AGENTIC ORCHESTRATION")
                        .font(.system(size: 36, weight: .black))
                        .tracking(4)
                        .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.3))
                        .blur(radius: 20)
                    
                    Text("AGENTIC ORCHESTRATION")
                        .font(.system(size: 36, weight: .black))
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.4), .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.8), value: viewModel.phaseProgress > 0.70)
    }
    
    // MARK: - Human Return (Simple, emotional)
    
    private var humanReturnText: some View {
        VStack(spacing: 20) {
            let progress = viewModel.phaseProgress
            
            if progress > 0.3 && progress < 0.7 {
                // Single powerful word
                Text("Rise.")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.7, blue: 0.85), .white],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            } else if progress >= 0.7 {
                Text("Your genius awaits.")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
    
    // MARK: - Personalization (Impact number)
    
    private var personalizationText: some View {
        VStack(spacing: 24) {
            Text("YOUR ANNUAL IMPACT")
                .font(.system(size: 14, weight: .bold))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.5))
            
            Text("$\(formatNumber(viewModel.annualImpact))")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.5, blue: 0.3), Color(red: 1.0, green: 0.85, blue: 0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.5, blue: 0.3).opacity(0.4), radius: 30)
        }
    }
    
    // MARK: - CTA (Minimal - narration does the work)
    
    private var ctaText: some View {
        VStack(spacing: 24) {
            let progress = viewModel.phaseProgress
            
            if progress > 0.7 {
                VStack(spacing: 16) {
                    Text("AUTOMATION ANYWHERE")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.4), .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if progress > 0.85 {
                        Text("Where will you lead?")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.phaseProgress)
    }
    
    // MARK: - Complete
    
    private var completeText: some View {
        Text("Experience Complete")
            .font(.system(size: 28, weight: .light))
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

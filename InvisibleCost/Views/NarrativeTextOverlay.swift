import SwiftUI

/// Text overlays per Tier 2 spec
struct NarrativeTextOverlay: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    
    var body: some View {
        ZStack {
            switch viewModel.currentPhase {
            case .spatialOverwhelm:
                OverwhelmText(progress: viewModel.phaseProgress)
                
            case .realityCrack:
                RealityCrackText(progress: viewModel.phaseProgress)
                
            case .humanFragment:
                HumanFragmentText(progress: viewModel.phaseProgress)
                
            case .dataChoreography:
                DataChoreographyText(progress: viewModel.phaseProgress)
                
            case .humanRestoration:
                // Visual speaks - minimal text
                EmptyView()
                
            case .exitMoment:
                ExitText(progress: viewModel.phaseProgress)
                
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentPhase)
    }
}

// MARK: - Spatial Overwhelm

struct OverwhelmText: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            if progress > 0.15 {
                Text("Every organization carries a hidden cost.")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            
            if progress > 0.35 {
                Text("Most leaders never see it.")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(30)
        .frame(width: 540)
    }
}

// MARK: - Reality Crack

struct RealityCrackText: View {
    let progress: Double
    
    var body: some View {
        // Per spec: Text floats mid-air after beam appears
        VStack(spacing: 10) {
            Text("Invisible work")
                .font(.system(size: 36, weight: .ultraLight))
                .tracking(4)
                .foregroundStyle(.white)
            
            Text("is costing more than you realize.")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
        }
        .opacity(progress > 0.1 ? 1 : 0)
        .scaleEffect(progress > 0.1 ? 1 : 0.95)
        .padding(36)
        .frame(width: 620)
        .animation(.easeOut(duration: 0.3), value: progress > 0.1)
    }
}

// MARK: - Human Fragment

struct HumanFragmentText: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 14) {
            if progress > 0.1 {
                Text("You made 247 decisions today.")
                    .font(.system(size: 20, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            if progress > 0.25 {
                Text("142 were unnecessary.")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(34)
        .frame(width: 520)
    }
}

// MARK: - Data Choreography

struct DataChoreographyText: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text("What if this work…")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
            
            if progress > 0.1 {
                Text("wasn't your work?")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(36)
        .frame(width: 560)
    }
}

// MARK: - Exit Moment

struct ExitText: View {
    let progress: Double
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        VStack(spacing: 28) {
            // Narrator closing per spec
            VStack(spacing: 14) {
                Text("Agentic automation")
                    .font(.system(size: 32, weight: .light))
                    .tracking(2)
                    .foregroundStyle(.white)
                
                Text("returns invisible work")
                    .font(.system(size: 26, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.85))
                
                Text("to the people who matter.")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.85, blue: 0.5),
                                Color(red: 1, green: 0.9, blue: 0.65)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            if progress > 0.25 {
                VStack(spacing: 14) {
                    Text("What could your organization become\nwith invisible work returned?")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Imagine 2026 teaser per spec
                    HStack(spacing: 10) {
                        Rectangle().fill(.white.opacity(0.25)).frame(width: 28, height: 1)
                        Text("Experience the full journey at Imagine 2026")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.35))
                        Rectangle().fill(.white.opacity(0.25)).frame(width: 28, height: 1)
                    }
                }
            }
            
            if progress > 0.45 {
                Button {
                    Task { await dismissImmersiveSpace() }
                } label: {
                    Text("END EXPERIENCE")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().stroke(.white.opacity(0.35), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(55)
        .frame(width: 620)
        .glassBackgroundEffect()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ExitText(progress: 0.8)
    }
    .environment(ExperienceViewModel())
}

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
                // Main narrative hides, arc attachments take over in ImmersiveNarrativeView
                EmptyView()
                
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentPhase)
    }
}

// MARK: - Volumetric CTA Arc Components

struct ExitCenterCTA: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        let progress = viewModel.phaseProgress
        VStack(spacing: 24) {
            Text("What could your organization become\nwith invisible work returned?")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            // Show sooner to avoid long wait after "wasn't your work?"
            if progress > 0.08 {
                Text("Experience the full journey at Imagine 2026")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            if progress > 0.2 {
                Button {
                    Task { await dismissImmersiveSpace() }
                } label: {
                    Text("END EXPERIENCE")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(2)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .glassBackgroundEffect()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
        .frame(width: 500)
        .glassBackgroundEffect()
        .opacity(viewModel.currentPhase == .exitMoment ? 1 : 0)
        .animation(.easeIn(duration: 1.0), value: viewModel.currentPhase == .exitMoment)
    }
}

struct ExitSideText: View {
    let text: String
    @Environment(ExperienceViewModel.self) private var viewModel
    
    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .ultraLight))
            .foregroundStyle(.white.opacity(0.6))
            .padding(30)
            .glassBackgroundEffect()
            .opacity(viewModel.currentPhase == .exitMoment ? 1 : 0)
            .animation(.easeIn(duration: 1.5), value: viewModel.currentPhase == .exitMoment)
    }
}

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
            // Text starts earlier to match ring appearance
            if progress > 0.15 {
                Text("What if this work…")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .transition(.opacity)
                
                // Delay "wasn't your work" until AFTER order established (approx > 0.6)
                if progress > 0.65 {
                    Text("wasn't your work?")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                }
            }
        }
        .padding(36)
        .frame(width: 560)
        .animation(.easeIn(duration: 1.0), value: progress > 0.15)
        .animation(.easeIn(duration: 0.8), value: progress > 0.65)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NarrativeTextOverlay()
            .environment(ExperienceViewModel())
    }
}

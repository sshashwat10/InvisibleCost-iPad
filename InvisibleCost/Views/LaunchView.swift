import SwiftUI

/// Premium launch view - minimal, cinematic entry point
/// Sets the tone before entering the immersive experience
struct LaunchView: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var isReady = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var isLaunching = false
    
    var body: some View {
        ZStack {
            // Deep black background
            Color.black.ignoresSafeArea()
            
            // Only show launch content when NOT in immersive mode
            if !viewModel.isExperienceActive {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo/Title area
                    VStack(spacing: 24) {
                        // "THE INVISIBLE COST" - premium typography
                        VStack(spacing: 8) {
                            Text("THE")
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .tracking(8)
                                .foregroundStyle(.white.opacity(0.5))
                            
                            Text("INVISIBLE")
                                .font(.system(size: 42, weight: .ultraLight, design: .default))
                                .tracking(12)
                                .foregroundStyle(.white)
                            
                            Text("COST")
                                .font(.system(size: 42, weight: .thin, design: .default))
                                .tracking(12)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
                        
                        // Subtle divider line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200, height: 1)
                            .opacity(showSubtitle ? 1 : 0)
                        
                        // Tagline
                        Text("A spatial narrative experience")
                            .font(.system(size: 13, weight: .light, design: .default))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.4))
                            .opacity(showSubtitle ? 1 : 0)
                            .offset(y: showSubtitle ? 0 : 10)
                    }
                    
                    Spacer()
                    
                    // Begin button
                    VStack(spacing: 16) {
                        Button {
                            beginExperience()
                        } label: {
                            HStack(spacing: 12) {
                                if isLaunching {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.black)
                                        .scaleEffect(0.8)
                                }
                                
                                Text(isLaunching ? "ENTERING..." : "BEGIN EXPERIENCE")
                                    .font(.system(size: 13, weight: .semibold, design: .default))
                                    .tracking(3)
                            }
                            .foregroundStyle(.black)
                            .frame(width: 240, height: 50)
                            .background(
                                Capsule()
                                    .fill(.white)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLaunching)
                        .opacity(showButton ? 1 : 0)
                        .scaleEffect(showButton ? 1 : 0.9)
                        
                        // Runtime indicator
                        Text("4-5 minute immersive experience")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(.white.opacity(0.3))
                            .opacity(showButton ? 1 : 0)
                    }
                    .padding(.bottom, 60)
                }
                
                // Automation Anywhere branding - subtle, bottom corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("AUTOMATION ANYWHERE")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.2))
                            .padding(20)
                    }
                }
            } else {
                // Experience is active - show minimal window or hide
                VStack {
                    Spacer()
                    Text("Experience in progress...")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                }
            }
        }
        .onAppear {
            animateIn()
        }
        .onChange(of: viewModel.currentPhase) { _, newPhase in
            if newPhase == .complete || newPhase == .waiting {
                // Reset when experience ends
                isLaunching = false
                viewModel.resetExperience()
            }
        }
        .onChange(of: viewModel.isExperienceActive) { _, isActive in
            if !isActive {
                isLaunching = false
            }
        }
    }
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            showTitle = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            showSubtitle = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.5)) {
            showButton = true
        }
        isReady = true
    }
    
    private func beginExperience() {
        guard !isLaunching else { return }
        isLaunching = true
        
        Task {
            let result = await openImmersiveSpace(id: "InvisibleCostExperience")
            
            switch result {
            case .opened:
                viewModel.startExperience()
            case .userCancelled, .error:
                isLaunching = false
            @unknown default:
                isLaunching = false
            }
        }
    }
}

#Preview(windowStyle: .plain) {
    LaunchView()
        .environment(ExperienceViewModel())
}


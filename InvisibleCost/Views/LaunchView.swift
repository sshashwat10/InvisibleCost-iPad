import SwiftUI

/// Launch window for the Invisible Cost Vision Pro experience
struct LaunchView: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImmersiveSpaceOpen = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                VStack(spacing: 16) {
                    Text("THE INVISIBLE COST")
                        .font(.system(size: 36, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.4),
                                    .white
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("A Spatial Narrative Experience")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                // Experience info
                VStack(spacing: 12) {
                    InfoRow(icon: "clock", text: "~3 minutes")
                    InfoRow(icon: "headphones", text: "Spatial audio recommended")
                    InfoRow(icon: "sparkles", text: "Full immersion experience")
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // Launch button
                Button {
                    launchExperience()
                } label: {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                        }
                        
                        Text(isLoading ? "Loading..." : "Begin Experience")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.85, blue: 0.4),
                                        Color(red: 1.0, green: 0.7, blue: 0.3)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                }
                .disabled(isLoading || isImmersiveSpaceOpen)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.top, 8)
                }
                
                // Reset button (if experience completed)
                if viewModel.currentPhase == .complete {
                    Button("Restart Experience") {
                        viewModel.reset()
                        isImmersiveSpaceOpen = false
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.cyan)
                    .padding(.top, 10)
                }
                
                Spacer()
                    .frame(height: 60)
                
                // Footer
                Text("AUTOMATION ANYWHERE")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(40)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func launchExperience() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            print("🚀 Launching immersive experience...")
            
            // Reset for fresh experience
            viewModel.reset()
            
            do {
                // Open immersive space
                let result = await openImmersiveSpace(id: "InvisibleCostExperience")
                
                switch result {
                case .opened:
                    print("✅ Immersive space opened successfully")
                    isImmersiveSpaceOpen = true
                    // Don't dismiss - let user see both windows or dismiss manually
                    
                case .error:
                    print("❌ Failed to open immersive space")
                    errorMessage = "Failed to open immersive space"
                    
                case .userCancelled:
                    print("⚠️ User cancelled immersive space")
                    errorMessage = "Cancelled by user"
                    
                @unknown default:
                    print("⚠️ Unknown result")
                    errorMessage = "Unknown error occurred"
                }
            }
            
            isLoading = false
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.cyan.opacity(0.8))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

#Preview {
    LaunchView()
        .environment(ExperienceViewModel())
}

import SwiftUI

/// The Invisible Cost - Davos 2026 Vision Pro Experience (Tier 2)
/// A premium spatial narrative revealing the hidden burden of modern work
/// and how agentic automation transforms it into clarity and human potential.
///
/// Emotional Arc: Pressure → Crisis → Pattern Break → Clarity → Human Return
/// Runtime: 4-5 minutes

@main
struct InvisibleCostApp: App {
    @State private var experienceViewModel = ExperienceViewModel()
    @State private var immersionStyle: ImmersionStyle = .full
    
    var body: some SwiftUI.Scene {
        // Launch window - minimal, premium feel
        WindowGroup {
            LaunchView()
                .environment(experienceViewModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 600, height: 400)
        
        // The immersive narrative experience
        ImmersiveSpace(id: "InvisibleCostExperience") {
            ImmersiveNarrativeView()
                .environment(experienceViewModel)
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}

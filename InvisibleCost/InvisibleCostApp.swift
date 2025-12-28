import SwiftUI

/// The Invisible Cost - A Spatial Narrative Experience for Vision Pro
/// Davos 2026 Tier 2 Experience

@main
struct InvisibleCostApp: App {
    @State private var viewModel = ExperienceViewModel()
    @State private var immersionStyle: ImmersionStyle = .full
    
    var body: some SwiftUI.Scene {
        WindowGroup(id: "LaunchWindow") {
            LaunchView()
                .environment(viewModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 480)
        
        ImmersiveSpace(id: "InvisibleCostExperience") {
            ImmersiveNarrativeView()
                .environment(viewModel)
        }
        .immersionStyle(selection: $immersionStyle, in: .progressive, .full)
    }
}


import SwiftUI
import Observation

/// The Invisible Cost - Vision Pro Experience Phases
/// Mirrors iPad Tier1Phase exactly for 1:1 narrative parity
/// TOTAL RUNTIME: ~189 seconds (3:09)
enum NarrativePhase: Int, CaseIterable {
    case waiting = 0
    case microColdOpen           // 00:00-00:07 - Black void, ambient audio
    case narratorFrame           // 00:07-00:26 - Opening narrations with text
    case spatialOverwhelm        // Finance vignette
    case realityCrack            // Supply chain vignette
    case humanFragment           // Healthcare vignette
    case patternBreak            // 00:43-00:51 - Pattern break transition
    case agenticOrchestration    // 00:51-01:19 - THE AWAKENING - 3D agents
    case humanReturn             // 01:19-01:41 - Restoration phase
    case personalization         // 01:41-01:57 - Interactive impact calculator
    case stillnessCTA            // 01:57-02:52 - Call to action
    case complete
    
    var duration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .microColdOpen: return 7          // Ambient intro
        case .narratorFrame: return 16         // Opening narrations
        case .spatialOverwhelm: return 9       // Finance vignette
        case .realityCrack: return 9           // Supply chain vignette
        case .humanFragment: return 9          // Healthcare vignette
        case .patternBreak: return 8           // Pattern break
        case .agenticOrchestration: return 28  // THE AWAKENING
        case .humanReturn: return 22           // Restoration
        case .personalization: return 16       // Interactive slider
        case .stillnessCTA: return 55          // CTA - full impact
        case .complete: return 0
        }
    }
    
    var next: NarrativePhase? {
        let all = NarrativePhase.allCases
        guard let currentIndex = all.firstIndex(of: self),
              currentIndex + 1 < all.count else { return nil }
        return all[currentIndex + 1]
    }
}

@Observable
class ExperienceViewModel {
    // Narrative State
    var currentPhase: NarrativePhase = .waiting
    var isExperienceActive: Bool = false
    var phaseProgress: Double = 0
    var phaseElapsedTime: TimeInterval = 0
    var totalElapsedTime: TimeInterval = 0
    
    // Personalization Data
    var lostHoursPerWeek: Double = 20
    var hourlyRate: Double = 150
    var teamSize: Double = 100
    
    var annualImpact: Double {
        return lostHoursPerWeek * 50 * teamSize * hourlyRate
    }
    
    // MARK: - Lifecycle
    
    func startExperience() {
        isExperienceActive = true
        currentPhase = .microColdOpen
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0
    }
    
    func advanceToNextPhase() {
        if let next = currentPhase.next {
            currentPhase = next
            phaseElapsedTime = 0
            phaseProgress = 0
        } else {
            endExperience()
        }
    }
    
    func endExperience() {
        isExperienceActive = false
        currentPhase = .complete
    }
    
    func reset() {
        currentPhase = .waiting
        isExperienceActive = false
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0
    }
    
    // MARK: - Update Logic
    
    func update(deltaTime: TimeInterval) {
        guard isExperienceActive, currentPhase != .waiting, currentPhase != .complete else { return }
        
        phaseElapsedTime += deltaTime
        totalElapsedTime += deltaTime
        
        let duration = currentPhase.duration
        if duration > 0 {
            phaseProgress = min(1.0, phaseElapsedTime / duration)
            
            if phaseProgress >= 1.0 {
                advanceToNextPhase()
            }
        }
    }
    
    // Alias for RealityKit update loop compatibility
    func updateProgress(deltaTime: TimeInterval) {
        update(deltaTime: deltaTime)
    }
}

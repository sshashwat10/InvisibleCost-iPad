import SwiftUI
import Observation

/// The Invisible Cost - Vision Pro Experience Phases
/// 1:1 PARITY with iPad - Exact same timing and narrative flow
/// TOTAL RUNTIME: ~150 seconds (2:30) - Matches iPad exactly
enum NarrativePhase: Int, CaseIterable {
    case waiting = 0
    case microColdOpen           // 00:00-00:06 - Black void, ambient audio
    case narratorFrame           // 00:06-00:23 - Opening narrations with text
    case spatialOverwhelm        // Finance vignette (5s)
    case realityCrack            // Supply chain vignette (5s)
    case humanFragment           // Healthcare vignette (5s)
    case patternBreak            // Pattern break transition
    case agenticOrchestration    // THE AWAKENING - 3D agents
    case humanReturn             // Restoration phase
    case personalization         // Interactive impact calculator
    case stillnessCTA            // Call to action
    case complete
    
    var duration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .microColdOpen: return 6          // Brief ambient intro (matches iPad)
        case .narratorFrame: return 17         // Opening narrations (matches iPad)
        case .spatialOverwhelm: return 5       // Finance vignette (15s total / 3)
        case .realityCrack: return 5           // Supply chain vignette
        case .humanFragment: return 5          // Healthcare vignette
        case .patternBreak: return 6           // Pattern break (matches iPad)
        case .agenticOrchestration: return 24  // THE AWAKENING (matches iPad)
        case .humanReturn: return 18           // Restoration (matches iPad)
        case .personalization: return 10       // Animated impact reveal
        case .stillnessCTA: return 50          // CTA (matches iPad)
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
        
        // If duration is 0 or very small, skip immediately to next phase
        if duration <= 0.01 {
            advanceToNextPhase()
            return
        }
        
        phaseProgress = min(1.0, phaseElapsedTime / duration)
        
        if phaseProgress >= 1.0 {
            advanceToNextPhase()
        }
    }
    
    // Alias for RealityKit update loop compatibility
    func updateProgress(deltaTime: TimeInterval) {
        update(deltaTime: deltaTime)
    }
}

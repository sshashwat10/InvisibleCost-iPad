import SwiftUI
import Observation

/// The Invisible Cost - Tier 1 (iPad) Narrative Phases
/// TOTAL RUNTIME: ~189 seconds (3:09) - ENHANCED impact sequence
/// All narrations complete within their phases at 60fps
enum Tier1Phase: Int, CaseIterable {
    case waiting = 0
    case microColdOpen         // 00:00-00:07 - Black screen, ambient audio
    case narratorFrame         // 00:07-00:26 - Opening narrations (11s audio)
    case humanVignettes        // 00:26-00:43 - 3 vignettes (9s audio)
    case patternBreak          // 00:43-00:51 - Pattern break (2s audio)
    case agenticOrchestration  // 00:51-01:19 - THE AWAKENING animation (7.3s audio)
    case humanReturn           // 01:19-01:41 - ENHANCED: 3 narrations (14s audio)
    case personalization       // 01:41-01:57 - Interactive slider
    case stillnessCTA          // 01:57-02:52 - ENHANCED: 5 narrations (43s audio) - full impact
    case complete
    
    var duration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .microColdOpen: return 7          // Ambient intro
        case .narratorFrame: return 19         // 3 narrations (~11s total)
        case .humanVignettes: return 17        // 3 vignettes (~9s total)
        case .patternBreak: return 8           // Single narration (2s)
        case .agenticOrchestration: return 28  // THE AWAKENING (7.3s narration)
        case .humanReturn: return 22           // ENHANCED: 3 narrations (~14s total)
        case .personalization: return 16       // Interactive slider
        case .stillnessCTA: return 55          // ENHANCED: 5 narrations (~43s) - full impact sequence
        case .complete: return 0
        }
    }
    
    var next: Tier1Phase? {
        let all = Tier1Phase.allCases
        guard let currentIndex = all.firstIndex(of: self),
              currentIndex + 1 < all.count else { return nil }
        return all[currentIndex + 1]
    }
}

@Observable
class ExperienceViewModel {
    // Narrative State
    var currentPhase: Tier1Phase = .waiting
    var isExperienceActive: Bool = false
    var phaseProgress: Double = 0
    var phaseElapsedTime: TimeInterval = 0
    var totalElapsedTime: TimeInterval = 0
    
    // Personalization Data (Tier 1 Spec)
    var lostHoursPerWeek: Double = 20
    var hourlyRate: Double = 150 // Estimated executive/professional rate
    var teamSize: Double = 100    // Default team size for impact calculation
    
    var annualImpact: Double {
        // (Lost Hours/Week) * (Weeks/Year) * (Team Size) * (Hourly Rate)
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
            
            // Auto-advance logic (can be overridden by user interaction in specific phases)
            if phaseProgress >= 1.0 {
                advanceToNextPhase()
            }
        }
    }
}


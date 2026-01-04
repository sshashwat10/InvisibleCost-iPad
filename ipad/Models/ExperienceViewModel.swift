import SwiftUI
import Observation

/// The Invisible Cost - Tier 1 (iPad) Narrative Phases
/// TOTAL RUNTIME: ~150 seconds (2:30) - Balanced pacing
/// Comfortable rhythm without feeling rushed
enum Tier1Phase: Int, CaseIterable {
    case waiting = 0
    case microColdOpen         // Brief ambient intro
    case narratorFrame         // Opening narrations
    case humanVignettes        // 3 vignettes
    case patternBreak          // Pattern break
    case agenticOrchestration  // THE AWAKENING animation
    case humanReturn           // 3 narrations
    case personalization       // Interactive slider
    case stillnessCTA          // Final impact sequence
    case complete
    
    var duration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .microColdOpen: return 6          // Brief ambient intro
        case .narratorFrame: return 17         // Opening narrations
        case .humanVignettes: return 15        // 3 vignettes
        case .patternBreak: return 6           // Pattern break beat
        case .agenticOrchestration: return 24  // THE AWAKENING
        case .humanReturn: return 18           // Restoration
        case .personalization: return 14       // Interactive slider
        case .stillnessCTA: return 50          // Final impact sequence
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


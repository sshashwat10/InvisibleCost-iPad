import SwiftUI
import Observation

/// The Invisible Cost - Tier 1 (iPad) Narrative Phases
/// TOTAL RUNTIME: ~5 minutes (300 seconds)
/// Spec-true implementation for Davos 2026
enum Tier1Phase: Int, CaseIterable {
    case waiting = 0
    case microColdOpen         // 00:00-00:07 - Black screen, ambient audio
    case narratorFrame         // 00:07-00:37 - "Every organization carries a hidden cost..."
    case humanVignettes        // 00:37-01:15 - Short emotional flashes (Finance, Supply Chain, Healthcare)
    case patternBreak          // 01:15-01:45 - White screen, silence, "What if this work... wasn't your work?"
    case agenticOrchestration  // 01:45-02:45 - Abstract data visualization (Chaos -> Clarity)
    case humanReturn           // 02:45-03:30 - Workers restored
    case personalization       // 03:30-04:30 - Interactive slider (Impact calculation)
    case stillnessCTA          // 04:30-05:00 - Stillness and final CTA
    case complete
    
    var duration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .microColdOpen: return 7
        case .narratorFrame: return 30
        case .humanVignettes: return 38
        case .patternBreak: return 30
        case .agenticOrchestration: return 60
        case .humanReturn: return 25
        case .personalization: return 30
        case .stillnessCTA: return 25
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


import SwiftUI
import Observation

/// Narrative phases per Tier 2 spec
/// TOTAL RUNTIME: ~4 minutes
enum NarrativePhase: Int, CaseIterable {
    case waiting = 0
    case spatialOverwhelm      // 00:00-00:25 - Floating windows, one shatters
    case realityCrack          // 00:25-00:37 - White beam, everything freezes
    case humanFragment         // 00:37-01:02 - Light shards fragment
    case dataChoreography      // 01:02-01:37 - Central object assembles from data points
    case humanRestoration      // 01:37-02:12 - Shards converge, color returns
    case exitMoment            // 02:12-02:42 - CTA
    case complete
    
    func duration(simSpeed: Double = 1.0) -> TimeInterval {
        // Updated timings for ~2 minute experience
        let base: TimeInterval
        switch self {
        case .waiting: base = 0
        case .spatialOverwhelm: base = 25    // Extended window build-up
        case .realityCrack: base = 12         // Breakout moment
        case .humanFragment: base = 20       // Shards drifting
        case .dataChoreography: base = 25    // Rings ordering (Chaos -> Order)
        case .humanRestoration: base = 20    // Calm restoration
        case .exitMoment: base = 18          // Fade out
        case .complete: base = 0
        }
        return base * simSpeed
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
    // Simulator-aware speed factor
    private var simSpeed: Double {
        #if targetEnvironment(simulator)
        return 1.0 // Normal speed on simulator now
        #else
        return 1.0
        #endif
    }
    
    var currentPhase: NarrativePhase = .waiting
    var phaseProgress: Double = 0
    var isExperienceActive: Bool = false
    var phaseElapsedTime: TimeInterval = 0
    var totalElapsedTime: TimeInterval = 0
    
    var overwhelmIntensity: Double = 0
    var notificationShattered: Bool = false
    
    func startExperience() {
        isExperienceActive = true
        currentPhase = .spatialOverwhelm
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0
        overwhelmIntensity = 0
        notificationShattered = false
    }
    
    func advanceToNextPhase() {
        guard let next = currentPhase.next else {
            endExperience()
            return
        }
        currentPhase = next
        phaseElapsedTime = 0
        phaseProgress = 0
    }
    
    func endExperience() {
        currentPhase = .complete
        isExperienceActive = false
    }
    
    func resetExperience() {
        currentPhase = .waiting
        phaseProgress = 0
        phaseElapsedTime = 0
        totalElapsedTime = 0
        isExperienceActive = false
        overwhelmIntensity = 0
        notificationShattered = false
    }
    
    func updateProgress(deltaTime: TimeInterval) {
        guard isExperienceActive, currentPhase != .waiting, currentPhase != .complete else { return }
        
        // Clamp delta to avoid large jumps when the simulator lags
        let clampedDelta = min(deltaTime, 0.05)
        phaseElapsedTime += clampedDelta
        totalElapsedTime += clampedDelta
        
        let phaseDuration = currentPhase.duration(simSpeed: simSpeed)
        if phaseDuration > 0 {
            phaseProgress = min(1.0, phaseElapsedTime / phaseDuration)
            
            if currentPhase == .spatialOverwhelm {
                overwhelmIntensity = phaseProgress
                // Trigger shatter at 80% through overwhelm
                if phaseProgress > 0.8 && !notificationShattered {
                    notificationShattered = true
                }
            }
            
            if phaseProgress >= 1.0 {
                advanceToNextPhase()
            }
        }
    }
}

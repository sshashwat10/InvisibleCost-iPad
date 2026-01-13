import SwiftUI
import Observation

// MARK: - Enhanced Experience Phases
/// The Invisible Cost - Enhanced Narrative Phases
/// TOTAL RUNTIME: ~180 seconds (3:00) - User-controlled pacing
/// Implements Neeti's feedback: agency, personalization, sucker punch moment

enum EnhancedPhase: Int, CaseIterable {
    case waiting = 0
    case industrySelection       // User chooses Finance/Supply Chain/Healthcare
    case buildingTension         // Industry-specific tension building
    case industryVignette        // Deep dive into chosen industry pain
    case patternBreak            // "But what if..."
    case suckerPunchReveal       // THE MOMENT - massive cost number
    case comparisonCarousel      // Relatable comparisons
    case agenticOrchestration    // Solution visualization
    case automationAnywhereReveal // Brand moment
    case humanReturn             // Restoration narrative
    case callToAction            // Final CTA
    case complete

    /// Phase duration (some are user-controlled)
    var duration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .industrySelection: return 0     // User-controlled
        case .buildingTension: return 12      // Timed
        case .industryVignette: return 15     // Timed
        case .patternBreak: return 0          // User-controlled (tap to continue)
        case .suckerPunchReveal: return 0     // User-controlled
        case .comparisonCarousel: return 0    // User-controlled
        case .agenticOrchestration: return 20 // Timed
        case .automationAnywhereReveal: return 10 // Timed
        case .humanReturn: return 15          // Timed
        case .callToAction: return 0          // User-controlled
        case .complete: return 0
        }
    }

    /// Whether this phase auto-advances or requires user interaction
    var isUserControlled: Bool {
        switch self {
        case .industrySelection, .patternBreak, .suckerPunchReveal,
             .comparisonCarousel, .callToAction:
            return true
        default:
            return false
        }
    }

    var next: EnhancedPhase? {
        let all = EnhancedPhase.allCases
        guard let currentIndex = all.firstIndex(of: self),
              currentIndex + 1 < all.count else { return nil }
        return all[currentIndex + 1]
    }

    /// Phase display name for debugging
    var displayName: String {
        switch self {
        case .waiting: return "Waiting"
        case .industrySelection: return "Industry Selection"
        case .buildingTension: return "Building Tension"
        case .industryVignette: return "Industry Vignette"
        case .patternBreak: return "Pattern Break"
        case .suckerPunchReveal: return "SUCKER PUNCH"
        case .comparisonCarousel: return "Comparisons"
        case .agenticOrchestration: return "Agentic Solution"
        case .automationAnywhereReveal: return "AA Reveal"
        case .humanReturn: return "Human Return"
        case .callToAction: return "Call to Action"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Enhanced Experience View Model

@Observable
class EnhancedExperienceViewModel {
    // MARK: - Core State
    var currentPhase: EnhancedPhase = .waiting
    var isExperienceActive: Bool = false
    var phaseProgress: Double = 0
    var phaseElapsedTime: TimeInterval = 0
    var totalElapsedTime: TimeInterval = 0

    // MARK: - Industry Selection (NEW)
    var selectedIndustry: Industry?

    // MARK: - Sucker Punch Data
    var suckerPunchData: SuckerPunchData? {
        guard let industry = selectedIndustry else { return nil }
        return IndustryContent.suckerPunchData(for: industry)
    }

    // MARK: - Comparison State
    var currentComparisonIndex: Int = 0
    var comparisonCards: [ComparisonCard] {
        guard let industry = selectedIndustry else { return [] }
        return IndustryContent.comparisonCards(for: industry)
    }

    // MARK: - Personalization Data (Preserved from original)
    var lostHoursPerWeek: Double = 20
    var hourlyRate: Double = 150
    var teamSize: Double = 100

    var annualImpact: Double {
        return lostHoursPerWeek * 50 * teamSize * hourlyRate
    }

    // MARK: - Lifecycle

    func startExperience() {
        isExperienceActive = true
        currentPhase = .industrySelection
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0
        selectedIndustry = nil
        currentComparisonIndex = 0

        print("[Experience] Started - Phase: \(currentPhase.displayName)")
    }

    func selectIndustry(_ industry: Industry) {
        selectedIndustry = industry
        print("[Experience] Industry selected: \(industry.displayName)")

        // Auto-advance after selection animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.advanceToNextPhase()
        }
    }

    func advanceToNextPhase() {
        if let next = currentPhase.next {
            let previousPhase = currentPhase
            currentPhase = next
            phaseElapsedTime = 0
            phaseProgress = 0

            print("[Experience] Phase transition: \(previousPhase.displayName) -> \(currentPhase.displayName)")

            // Reset comparison index when entering carousel
            if currentPhase == .comparisonCarousel {
                currentComparisonIndex = 0
            }
        } else {
            endExperience()
        }
    }

    func advanceComparison() {
        if currentComparisonIndex < comparisonCards.count {
            currentComparisonIndex += 1
            print("[Experience] Comparison \(currentComparisonIndex)/\(comparisonCards.count)")
        }

        // Auto-advance when all comparisons shown
        if currentComparisonIndex >= comparisonCards.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.advanceToNextPhase()
            }
        }
    }

    func endExperience() {
        isExperienceActive = false
        currentPhase = .complete
        print("[Experience] Completed - Total time: \(Int(totalElapsedTime))s")
    }

    func reset() {
        currentPhase = .waiting
        isExperienceActive = false
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0
        selectedIndustry = nil
        currentComparisonIndex = 0
        print("[Experience] Reset")
    }

    // MARK: - Update Logic (Called from timer)

    func update(deltaTime: TimeInterval) {
        guard isExperienceActive,
              currentPhase != .waiting,
              currentPhase != .complete else { return }

        phaseElapsedTime += deltaTime
        totalElapsedTime += deltaTime

        let duration = currentPhase.duration
        if duration > 0 {
            phaseProgress = min(1.0, phaseElapsedTime / duration)

            // Auto-advance for timed phases
            if phaseProgress >= 1.0 && !currentPhase.isUserControlled {
                advanceToNextPhase()
            }
        }
    }

    // MARK: - Audio Keys

    /// Get the appropriate narration key for current state
    func narrationKey(for phase: EnhancedPhase, subIndex: Int = 0) -> String? {
        guard let industry = selectedIndustry else { return nil }

        switch phase {
        case .industrySelection:
            return "choose_industry"
        case .buildingTension:
            return "building_\(industry.rawValue)"
        case .industryVignette:
            return "vignette_\(industry.rawValue)_enhanced"
        case .patternBreak:
            return "pattern_break_enhanced"
        case .suckerPunchReveal:
            return "sucker_punch_\(industry.rawValue)"
        case .comparisonCarousel:
            let index = min(subIndex, 2)
            return "comparison_\(industry.rawValue)_\(index + 1)"
        case .agenticOrchestration:
            return "agentic_enhanced"
        case .automationAnywhereReveal:
            return "aa_reveal_enhanced"
        case .humanReturn:
            switch subIndex {
            case 0: return "restoration_enhanced"
            case 1: return "breathe"
            case 2: return "purpose"
            default: return nil
            }
        case .callToAction:
            return "final_cta_enhanced"
        default:
            return nil
        }
    }
}

// MARK: - Phase Extensions for Audio

extension EnhancedPhase {
    /// All narration keys needed for this phase
    var narratorKeys: [String] {
        switch self {
        case .waiting, .complete, .comparisonCarousel:
            return []  // Handled dynamically
        case .industrySelection:
            return ["choose_industry"]
        case .buildingTension:
            return []  // Dynamic based on industry
        case .industryVignette:
            return []  // Dynamic based on industry
        case .patternBreak:
            return ["pattern_break_enhanced"]
        case .suckerPunchReveal:
            return []  // Dynamic based on industry
        case .agenticOrchestration:
            return ["agentic_enhanced"]
        case .automationAnywhereReveal:
            return ["aa_reveal_enhanced"]
        case .humanReturn:
            return ["restoration_enhanced", "breathe", "purpose"]
        case .callToAction:
            return ["final_cta_enhanced"]
        }
    }
}

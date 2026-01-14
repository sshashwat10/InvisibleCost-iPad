import SwiftUI
import Observation

// MARK: - Enhanced Experience Phases
/// The Invisible Cost - Overhauled Narrative Phases (Department-based)
/// TOTAL RUNTIME: ~180 seconds (3:00) - User-controlled pacing
/// Implements Neeti's feedback: agency, personalization, sourced data
/// NOW WITH DEPARTMENT-SPECIFIC CONTENT (P2P, O2C, Customer Support, ITSM)

enum Tier1Phase: Int, CaseIterable {
    case waiting = 0
    case emotionalIntro          // 10s emotional grounding before interaction
    case departmentSelection     // User chooses P2P, O2C, Customer Support, ITSM
    case departmentInput         // User enters department-specific inputs
    case buildingTension         // Department-specific tension building
    case departmentVignette      // Deep dive into chosen department pain
    case patternBreak            // "But what if..."
    case suckerPunchReveal       // THE MOMENT - massive cost number (uses calculated data)
    case costBreakdown           // Visual breakdown of direct/indirect/invisible costs
    case comparisonCarousel      // Relatable comparisons
    case agenticOrchestration    // Solution visualization
    case automationAnywhereReveal // Brand moment
    case aaValueProposition      // Sourced ROI/savings (Forrester TEI)
    case humanReturn             // Restoration narrative
    case callToAction            // Final CTA
    case complete

    /// Base phase duration - ULTRA-TIGHTENED for snappy experience
    /// Based on MEASURED audio durations from expressive regeneration
    /// Formula: audioLength + 0.5-1s buffer (crisp, not sluggish)
    var baseDuration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .emotionalIntro: return 10.0     // opening_1 (2.9s) + opening_2 (2.3s) + visual transitions
        case .departmentSelection: return 0   // User-controlled
        case .departmentInput: return 0       // User-controlled (continue after narration)
        case .buildingTension: return 15      // ~14s audio + 1s buffer
        case .departmentVignette: return 5    // ~3s audio + 2s for metrics to appear
        case .patternBreak: return 0          // User-controlled (tap to continue)
        case .suckerPunchReveal: return 0     // User-controlled
        case .costBreakdown: return 0         // User-controlled (review at own pace)
        case .comparisonCarousel: return 0    // User-controlled
        case .agenticOrchestration: return 11 // 10s audio + 1s buffer
        case .automationAnywhereReveal: return 0 // Duration calculated dynamically from audio
        case .aaValueProposition: return 0    // User-controlled (review Forrester data)
        case .humanReturn: return 10          // restoration(2.2) + purpose(7.6) + gap
        case .callToAction: return 0          // User-controlled
        case .complete: return 0
        }
    }

    /// Whether this phase auto-advances or requires user interaction
    var isUserControlled: Bool {
        switch self {
        case .departmentSelection, .departmentInput, .patternBreak, .suckerPunchReveal,
             .costBreakdown, .comparisonCarousel, .aaValueProposition, .callToAction:
            return true
        case .emotionalIntro:
            return false
        default:
            return false
        }
    }

    var next: Tier1Phase? {
        let all = Tier1Phase.allCases
        guard let currentIndex = all.firstIndex(of: self),
              currentIndex + 1 < all.count else { return nil }
        return all[currentIndex + 1]
    }

    /// Phase display name for debugging
    var displayName: String {
        switch self {
        case .waiting: return "Waiting"
        case .emotionalIntro: return "Emotional Intro"
        case .departmentSelection: return "Department Selection"
        case .departmentInput: return "Department Input"
        case .buildingTension: return "Building Tension"
        case .departmentVignette: return "Department Vignette"
        case .patternBreak: return "Pattern Break"
        case .suckerPunchReveal: return "SUCKER PUNCH"
        case .costBreakdown: return "Cost Breakdown"
        case .comparisonCarousel: return "Comparisons"
        case .agenticOrchestration: return "Agentic Solution"
        case .automationAnywhereReveal: return "AA Reveal"
        case .aaValueProposition: return "AA Value Proposition"
        case .humanReturn: return "Human Return"
        case .callToAction: return "Call to Action"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Enhanced Experience View Model

@Observable
class ExperienceViewModel {
    // MARK: - Core State
    var currentPhase: Tier1Phase = .waiting
    var isExperienceActive: Bool = false
    var phaseProgress: Double = 0
    var phaseElapsedTime: TimeInterval = 0
    var totalElapsedTime: TimeInterval = 0

    // MARK: - Audio Sync State
    /// Tracks whether narration for current phase has completed
    var narrationComplete: Bool = false
    /// Tracks whether we're waiting for narration to complete before advancing
    var waitingForNarration: Bool = false
    /// The calculated duration for the current phase (based on audio)
    private var currentPhaseDuration: TimeInterval = 0

    // MARK: - Department Selection (Replaces Industry)
    var selectedDepartment: Department?

    // MARK: - User Input Data
    var userInput = UserInputData()

    // MARK: - Calculated Cost Breakdown (Computed)
    var costBreakdownResult: CostBreakdown {
        guard selectedDepartment != nil else { return .empty }
        let calculator = CostCalculator(userInput: userInput)
        return calculator.calculateInvisibleCost()
    }

    // MARK: - Savings Projection (Computed)
    var savingsProjection: SavingsProjection {
        let calculator = SavingsCalculator(costBreakdown: costBreakdownResult, userInput: userInput)
        return calculator.calculateSavingsProjection()
    }

    // MARK: - Comparison State
    var currentComparisonIndex: Int = 0
    var comparisonCards: [ComparisonCard] {
        guard let department = selectedDepartment else { return [] }
        return DepartmentContent.comparisonCards(for: department, costBreakdown: costBreakdownResult)
    }

    // MARK: - Display Name (Generic since company name was removed)
    /// Returns "YOUR ORGANIZATION" for display - company name input was removed per Neeti feedback
    var displayCompanyName: String {
        "Your Organization"
    }

    var shortCompanyName: String {
        "Your Org"
    }

    var hasCustomCompanyName: Bool {
        false  // Always false since we no longer collect company name
    }

    // MARK: - Legacy Compatibility Properties

    /// Legacy: selectedIndustry - now maps to selectedDepartment for old view compatibility
    var selectedIndustry: Department? {
        get { selectedDepartment }
        set { selectedDepartment = newValue }
    }

    /// Legacy: teamSize - maps to appropriate department input
    var teamSize: Double {
        get { Double(userInput.employeeCount) }
        set { userInput.employeeCount = Int(newValue) }
    }

    /// Legacy: lostHoursPerWeek - computed from inputs
    var lostHoursPerWeek: Double {
        get { costBreakdownResult.annualHours / 52 }
        set { /* No-op for legacy compatibility */ }
    }

    /// Legacy: hourlyRate
    var hourlyRate: Double {
        get { userInput.averageHourlyRate }
        set { userInput.averageHourlyRate = newValue }
    }

    /// Legacy: calculatedAnnualCost - now uses cost calculator
    var calculatedAnnualCost: Double {
        costBreakdownResult.totalCost
    }

    /// Legacy: formattedAnnualCost
    var formattedAnnualCost: String {
        costBreakdownResult.formattedTotalCost
    }

    /// Legacy: annualImpact
    var annualImpact: Double {
        costBreakdownResult.totalCost
    }

    /// Legacy: suckerPunchData - now uses calculated cost breakdown
    var suckerPunchData: SuckerPunchData? {
        guard selectedDepartment != nil else { return nil }
        return SuckerPunchData(
            amount: Int(costBreakdownResult.totalCost),
            formattedAmount: costBreakdownResult.formattedTotalCost,
            spokenAmount: costBreakdownResult.spokenTotalCost,
            audioKey: "sucker_punch_reveal"
        )
    }

    // MARK: - Lifecycle

    func startExperience() {
        isExperienceActive = true
        currentPhase = .emotionalIntro  // Start with emotional grounding
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0
        selectedDepartment = nil
        currentComparisonIndex = 0
        narrationComplete = false
        waitingForNarration = false

        // Reset user input to defaults
        userInput = UserInputData()

        // Calculate initial phase duration
        updatePhaseDuration()

        print("[Experience] Started - Phase: \(currentPhase.displayName)")
    }

    func selectDepartment(_ department: Department) {
        selectedDepartment = department
        userInput.department = department
        print("[Experience] Department selected: \(department.displayName)")

        // Snappy auto-advance after selection animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.advanceToNextPhase()
        }
    }

    /// Legacy compatibility - selectIndustry now maps to selectDepartment
    func selectIndustry(_ department: Department) {
        selectDepartment(department)
    }

    func advanceToNextPhase() {
        if let next = currentPhase.next {
            let previousPhase = currentPhase
            currentPhase = next
            phaseElapsedTime = 0
            phaseProgress = 0
            narrationComplete = false
            waitingForNarration = false

            // Update duration for new phase
            updatePhaseDuration()

            print("[Experience] Phase transition: \(previousPhase.displayName) -> \(currentPhase.displayName) (duration: \(String(format: "%.1f", currentPhaseDuration))s)")

            // Reset comparison index when entering carousel
            if currentPhase == .comparisonCarousel {
                currentComparisonIndex = 0
            }
        } else {
            endExperience()
        }
    }

    /// Called by NarrativeView when a narration completes
    func onNarrationComplete() {
        narrationComplete = true
        let completedPhase = currentPhase
        print("[Experience] Narration completed for phase: \(completedPhase.displayName)")

        // NEVER auto-advance from user-controlled phases - they require explicit user action
        guard !completedPhase.isUserControlled else {
            print("[Experience] Phase \(completedPhase.displayName) is user-controlled, not auto-advancing")
            return
        }

        // If we were waiting for narration to advance, do it now (snappy transition)
        if waitingForNarration {
            waitingForNarration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                // Double-check we're still on the same phase and it's not user-controlled
                guard self.currentPhase == completedPhase, !self.currentPhase.isUserControlled else { return }
                self.advanceToNextPhase()
            }
            return
        }

        // For certain timed phases, advance shortly after narration completes
        if shouldAdvanceOnNarrationComplete(completedPhase) && phaseProgress >= 0.25 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                // Double-check we're still on the same phase and it's not user-controlled
                guard self.currentPhase == completedPhase, !self.currentPhase.isUserControlled else { return }
                self.advanceToNextPhase()
            }
        }
    }

    /// Phases that should advance shortly after narration completes
    private func shouldAdvanceOnNarrationComplete(_ phase: Tier1Phase) -> Bool {
        switch phase {
        case .departmentVignette, .buildingTension, .automationAnywhereReveal, .humanReturn:
            return true
        default:
            return false
        }
    }

    func advanceComparison() {
        if currentComparisonIndex < comparisonCards.count {
            currentComparisonIndex += 1
            print("[Experience] Comparison \(currentComparisonIndex)/\(comparisonCards.count)")
        }

        // Snappy auto-advance when all comparisons shown
        if currentComparisonIndex >= comparisonCards.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.advanceToNextPhase()
            }
        }
    }

    func endExperience() {
        isExperienceActive = false
        currentPhase = .complete
        print("[Experience] Completed - Total time: \(Int(totalElapsedTime))s")

        // DEMO-SAFE: Auto-reset after short delay
        // Ensures next attendee always starts fresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.reset()
        }
    }

    /// DEMO-SAFE: Full reset to clean start screen
    /// This is idempotent - safe to call multiple times
    /// Called on: app foreground, experience completion, manual reset
    func reset() {
        print("[Experience] Demo-safe reset initiated")

        // Navigation / phase
        currentPhase = .waiting
        isExperienceActive = false
        phaseElapsedTime = 0
        totalElapsedTime = 0
        phaseProgress = 0

        // User inputs
        selectedDepartment = nil
        userInput = UserInputData()

        // Comparison state
        currentComparisonIndex = 0

        // Audio sync flags
        narrationComplete = false
        waitingForNarration = false

        // Stop all audio
        AudioManager.shared.stopAll()

        print("[Experience] Reset complete - ready for new attendee")
    }

    // MARK: - Phase Duration Calculation

    private func updatePhaseDuration() {
        // Get the audio-based minimum duration
        let audioDuration = AudioManager.shared.getMinimumPhaseDuration(for: currentPhase, department: selectedDepartment)

        // Use the maximum of base duration and audio-calculated duration
        currentPhaseDuration = max(currentPhase.baseDuration, audioDuration)

        // For user-controlled phases, duration is 0 (infinite until user action)
        if currentPhase.isUserControlled {
            currentPhaseDuration = 0
        }
    }

    /// Get the effective duration for the current phase
    var effectivePhaseDuration: TimeInterval {
        return currentPhaseDuration
    }

    // MARK: - Update Logic (Called from timer)

    func update(deltaTime: TimeInterval) {
        guard isExperienceActive,
              currentPhase != .waiting,
              currentPhase != .complete else { return }

        phaseElapsedTime += deltaTime
        totalElapsedTime += deltaTime

        let duration = currentPhaseDuration

        if duration > 0 {
            phaseProgress = min(1.0, phaseElapsedTime / duration)

            // For timed phases, check if we should advance
            if phaseProgress >= 1.0 && !currentPhase.isUserControlled {
                // If narration hasn't completed yet, wait for it
                if !narrationComplete && AudioManager.shared.isNarrationPlaying {
                    waitingForNarration = true
                } else {
                    advanceToNextPhase()
                }
            }
        } else {
            // User-controlled phase - progress for animations
            phaseProgress = min(1.0, phaseElapsedTime / 10.0)
        }
    }

    // MARK: - Audio Keys

    /// Get the appropriate narration key for current state
    func narrationKey(for phase: Tier1Phase, subIndex: Int = 0) -> String? {
        // Handle phases that don't need department selection
        if phase == .emotionalIntro {
            switch subIndex {
            case 0: return "opening_1"
            case 1: return "opening_2"
            default: return nil
            }
        }

        guard let department = selectedDepartment else {
            if phase == .departmentSelection {
                return "choose_department"
            }
            return nil
        }

        let deptKey = department.rawValue

        switch phase {
        case .emotionalIntro:
            switch subIndex {
            case 0: return "opening_1"
            case 1: return "opening_2"
            default: return nil
            }
        case .departmentSelection:
            return "choose_department"
        case .departmentInput:
            return "department_input"
        case .buildingTension:
            return "building_\(deptKey)"
        case .departmentVignette:
            return "vignette_\(deptKey)"
        case .patternBreak:
            return "pattern_break_enhanced"
        case .suckerPunchReveal:
            return "sucker_punch_reveal"  // General reveal, numbers shown visually
        case .costBreakdown:
            return "cost_breakdown"
        case .comparisonCarousel:
            let index = min(subIndex, 2)
            return "comparison_\(deptKey)_\(index + 1)"
        case .agenticOrchestration:
            return "agentic_enhanced"
        case .automationAnywhereReveal:
            return "aa_reveal_forrester"  // Sourced: "262% ROI. Payback under 12 months."
        case .aaValueProposition:
            return "aa_value_\(deptKey)"
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

extension Tier1Phase {
    /// All narration keys needed for this phase
    var narratorKeys: [String] {
        switch self {
        case .waiting, .complete, .comparisonCarousel:
            return []
        case .emotionalIntro:
            return ["opening_1", "opening_2"]
        case .departmentSelection:
            return ["choose_department"]
        case .departmentInput:
            return ["department_input"]
        case .buildingTension:
            return []  // Dynamic based on department
        case .departmentVignette:
            return []  // Dynamic based on department
        case .patternBreak:
            return ["pattern_break_enhanced"]
        case .suckerPunchReveal:
            return ["sucker_punch_reveal"]
        case .costBreakdown:
            return ["cost_breakdown"]
        case .agenticOrchestration:
            return ["agentic_enhanced"]
        case .automationAnywhereReveal:
            return ["aa_reveal_forrester"]
        case .aaValueProposition:
            return []  // Dynamic based on department
        case .humanReturn:
            return ["restoration_enhanced", "breathe", "purpose"]
        case .callToAction:
            return ["final_cta_enhanced"]
        }
    }
}

// MARK: - Supporting Data Structures (Legacy Compatibility)

struct SuckerPunchData {
    let amount: Int
    let formattedAmount: String
    let spokenAmount: String
    let audioKey: String
}

// MARK: - Legacy Industry Type Alias
/// For backward compatibility with existing views
typealias Industry = Department

// MARK: - Legacy IndustryTheme Type Alias
/// For backward compatibility with existing animations
typealias IndustryTheme = DepartmentTheme

// MARK: - Legacy IndustryContent
/// For backward compatibility with existing views
struct IndustryContent {

    static func buildingTensionText(for department: Department) -> (line1: String, line2: String, teaser: String) {
        DepartmentContent.buildingTensionText(for: department)
    }

    static func vignetteData(for department: Department) -> (title: String, subtitle: String, metrics: [(value: String, label: String)]) {
        DepartmentContent.vignetteData(for: department)
    }

    static func suckerPunchData(for department: Department) -> SuckerPunchData {
        // Return legacy-compatible data
        SuckerPunchData(
            amount: 0,
            formattedAmount: "$0",
            spokenAmount: "zero dollars",
            audioKey: "sucker_punch_reveal"
        )
    }

    static func comparisonCards(for department: Department) -> [ComparisonCard] {
        DepartmentContent.comparisonCards(for: department, costBreakdown: .empty)
    }

    enum AudioPhase {
        case buildingTension
        case vignette
        case suckerPunch
        case comparison(Int)
    }

    static func audioKey(for department: Department, phase: AudioPhase) -> String {
        let deptKey = department.rawValue
        switch phase {
        case .buildingTension:
            return "building_\(deptKey)"
        case .vignette:
            return "vignette_\(deptKey)"
        case .suckerPunch:
            return "sucker_punch_reveal"
        case .comparison(let index):
            return "comparison_\(deptKey)_\(index + 1)"
        }
    }
}

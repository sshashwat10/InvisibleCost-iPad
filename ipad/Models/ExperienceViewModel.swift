import SwiftUI
import Observation

// MARK: - Enhanced Experience Phases
/// The Invisible Cost - Enhanced Narrative Phases
/// TOTAL RUNTIME: ~180 seconds (3:00) - User-controlled pacing
/// Implements Neeti's feedback: agency, personalization, sucker punch moment
/// NOW WITH PROPER AUDIO-SYNCED DURATIONS

enum Tier1Phase: Int, CaseIterable {
    case waiting = 0
    case industrySelection       // User chooses Finance/Supply Chain/Healthcare
    case personalInput           // NEW: User enters team size, hours lost, hourly rate
    case buildingTension         // Industry-specific tension building
    case industryVignette        // Deep dive into chosen industry pain
    case patternBreak            // "But what if..."
    case suckerPunchReveal       // THE MOMENT - massive cost number (uses personalized data)
    case comparisonCarousel      // Relatable comparisons
    case agenticOrchestration    // Solution visualization
    case automationAnywhereReveal // Brand moment
    case humanReturn             // Restoration narrative
    case callToAction            // Final CTA
    case complete

    /// Base phase duration - UPDATED based on actual audio file lengths + visual animation time
    /// These ensure animations complete AND narration finishes without rushing
    /// Formula: max(audioLength, animationNeed) + 2s buffer
    var baseDuration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .industrySelection: return 0     // User-controlled
        case .personalInput: return 0         // User-controlled (continue after narration)
        case .buildingTension: return 20      // ~15s audio + 5s visual buildup buffer
        case .industryVignette: return 12     // ~5.6s audio + 6s for metrics animation
        case .patternBreak: return 0          // User-controlled (tap to continue)
        case .suckerPunchReveal: return 0     // User-controlled
        case .comparisonCarousel: return 0    // User-controlled
        case .agenticOrchestration: return 20 // ~12.6s audio + animation time
        case .automationAnywhereReveal: return 10 // ~5.4s audio + logo reveal animation
        case .humanReturn: return 18          // ~13s total for 3 narrations (3+2.5+7.4) + buffer
        case .callToAction: return 0          // User-controlled
        case .complete: return 0
        }
    }

    /// Whether this phase auto-advances or requires user interaction
    var isUserControlled: Bool {
        switch self {
        case .industrySelection, .personalInput, .patternBreak, .suckerPunchReveal,
             .comparisonCarousel, .callToAction:
            return true
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
        case .industrySelection: return "Industry Selection"
        case .personalInput: return "Personal Input"
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

    // MARK: - Personalization Data (Enhanced for Davos 2026)
    var companyName: String = ""
    var teamSize: Double = 100
    var lostHoursPerWeek: Double = 20
    var hourlyRate: Double = 150

    /// Calculated annual cost based on user input: teamSize * lostHoursPerWeek * 52 weeks * hourlyRate
    var calculatedAnnualCost: Double {
        return teamSize * lostHoursPerWeek * 52.0 * hourlyRate
    }

    /// Formatted annual cost for display
    var formattedAnnualCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: calculatedAnnualCost)) ?? "$0"
    }

    /// Legacy computed property for compatibility
    var annualImpact: Double {
        return calculatedAnnualCost
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
        narrationComplete = false
        waitingForNarration = false

        // Reset personalization to defaults
        companyName = ""
        teamSize = 100
        lostHoursPerWeek = 20
        hourlyRate = 150

        // Calculate initial phase duration
        updatePhaseDuration()

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
        print("[Experience] Narration completed for phase: \(currentPhase.displayName)")

        // If we were waiting for narration to advance, do it now (with a small delay for breathing room)
        if waitingForNarration && !currentPhase.isUserControlled {
            waitingForNarration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.advanceToNextPhase()
            }
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
        narrationComplete = false
        waitingForNarration = false
        print("[Experience] Reset")
    }

    // MARK: - Phase Duration Calculation

    private func updatePhaseDuration() {
        // Get the audio-based minimum duration
        let audioDuration = AudioManager.shared.getMinimumPhaseDuration(for: currentPhase, industry: selectedIndustry)

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
                    // Don't advance yet, wait for narrationComplete callback
                } else {
                    // Narration is done or wasn't playing, advance
                    advanceToNextPhase()
                }
            }
        } else {
            // User-controlled phase - progress is based on elapsed time for animations
            // but won't auto-advance
            phaseProgress = min(1.0, phaseElapsedTime / 10.0) // Normalize to 10 seconds for animation purposes
        }
    }

    // MARK: - Audio Keys

    /// Get the appropriate narration key for current state
    func narrationKey(for phase: Tier1Phase, subIndex: Int = 0) -> String? {
        guard let industry = selectedIndustry else {
            if phase == .industrySelection {
                return "choose_industry"
            }
            return nil
        }

        switch phase {
        case .industrySelection:
            return "choose_industry"
        case .personalInput:
            return "personal_input"  // NEW: Narration for personalization
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

extension Tier1Phase {
    /// All narration keys needed for this phase
    var narratorKeys: [String] {
        switch self {
        case .waiting, .complete, .comparisonCarousel:
            return []  // Handled dynamically
        case .industrySelection:
            return ["choose_industry"]
        case .personalInput:
            return ["personal_input"]  // NEW
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


// MARK: - Industry Data

import SwiftUI

// MARK: - Industry Types

/// Represents the three industry verticals for the experience
enum Industry: String, CaseIterable, Identifiable {
    case finance = "finance"
    case supplyChain = "supply"
    case healthcare = "health"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .finance: return "FINANCE"
        case .supplyChain: return "SUPPLY CHAIN"
        case .healthcare: return "HEALTHCARE"
        }
    }

    var icon: String {
        switch self {
        case .finance: return "chart.bar.xaxis"
        case .supplyChain: return "shippingbox"
        case .healthcare: return "heart.text.square"
        }
    }

    var theme: IndustryTheme {
        switch self {
        case .finance:
            return IndustryTheme(
                primary: Color(red: 0.23, green: 0.51, blue: 0.96),      // #3B82F6
                accent: Color(red: 0.37, green: 0.62, blue: 1.0),
                glow: Color(red: 0.15, green: 0.35, blue: 0.75),
                gradient: [
                    Color(red: 0.15, green: 0.35, blue: 0.75),
                    Color(red: 0.23, green: 0.51, blue: 0.96)
                ]
            )
        case .supplyChain:
            return IndustryTheme(
                primary: Color(red: 0.96, green: 0.62, blue: 0.04),      // #F59E0B
                accent: Color(red: 1.0, green: 0.72, blue: 0.22),
                glow: Color(red: 0.75, green: 0.45, blue: 0.02),
                gradient: [
                    Color(red: 0.75, green: 0.45, blue: 0.02),
                    Color(red: 0.96, green: 0.62, blue: 0.04)
                ]
            )
        case .healthcare:
            return IndustryTheme(
                primary: Color(red: 0.08, green: 0.72, blue: 0.65),      // #14B8A6
                accent: Color(red: 0.18, green: 0.82, blue: 0.75),
                glow: Color(red: 0.05, green: 0.55, blue: 0.48),
                gradient: [
                    Color(red: 0.05, green: 0.55, blue: 0.48),
                    Color(red: 0.08, green: 0.72, blue: 0.65)
                ]
            )
        }
    }
}

// MARK: - Industry Theme

struct IndustryTheme {
    let primary: Color
    let accent: Color
    let glow: Color
    let gradient: [Color]
}

// MARK: - Industry Content Data

/// All content specific to each industry vertical
struct IndustryContent {

    // MARK: - Building Tension Content

    static func buildingTensionText(for industry: Industry) -> (line1: String, line2: String, teaser: String) {
        switch industry {
        case .finance:
            return (
                "Every report. Every reconciliation.",
                "Every manual entry that keeps your team from the work that matters.",
                "Your team processes 1,247 transactions daily..."
            )
        case .supplyChain:
            return (
                "Every shipment tracked by hand.",
                "Every exception managed manually. Every delay cascading through your network.",
                "Your network spans 847 touchpoints..."
            )
        case .healthcare:
            return (
                "Every chart note. Every referral fax.",
                "Every authorization that keeps healers from healing.",
                "Your clinicians handle 423 administrative tasks daily..."
            )
        }
    }

    // MARK: - Vignette Content

    static func vignetteData(for industry: Industry) -> (title: String, subtitle: String, metrics: [(value: String, label: String)]) {
        switch industry {
        case .finance:
            return (
                title: "FINANCE",
                subtitle: "Reconciliation Fatigue",
                metrics: [
                    ("4.7h", "daily reconciliation"),
                    ("340", "manual entries"),
                    ("23", "systems touched")
                ]
            )
        case .supplyChain:
            return (
                title: "SUPPLY CHAIN",
                subtitle: "Inventory Friction",
                metrics: [
                    ("3.2h", "tracking overhead"),
                    ("89%", "manual updates"),
                    ("$2.4M", "annual waste")
                ]
            )
        case .healthcare:
            return (
                title: "HEALTHCARE",
                subtitle: "Administrative Burden",
                metrics: [
                    ("5.1h", "paperwork daily"),
                    ("67%", "non-clinical tasks"),
                    ("142", "forms per week")
                ]
            )
        }
    }

    // MARK: - Sucker Punch Data (THE MOMENT)

    static func suckerPunchData(for industry: Industry) -> SuckerPunchData {
        switch industry {
        case .finance:
            return SuckerPunchData(
                amount: 47_500_000,
                formattedAmount: "$47,500,000",
                spokenAmount: "Forty-seven point five million dollars",
                audioKey: "sucker_punch_finance"
            )
        case .supplyChain:
            return SuckerPunchData(
                amount: 38_200_000,
                formattedAmount: "$38,200,000",
                spokenAmount: "Thirty-eight point two million dollars",
                audioKey: "sucker_punch_supply"
            )
        case .healthcare:
            return SuckerPunchData(
                amount: 52_800_000,
                formattedAmount: "$52,800,000",
                spokenAmount: "Fifty-two point eight million dollars",
                audioKey: "sucker_punch_health"
            )
        }
    }

    // MARK: - Comparison Data

    static func comparisonCards(for industry: Industry) -> [ComparisonCard] {
        switch industry {
        case .finance:
            return [
                ComparisonCard(
                    icon: "person.fill",
                    number: "950",
                    unit: "senior analyst salaries",
                    emphasis: "Gone.",
                    audioKey: "comparison_finance_1"
                ),
                ComparisonCard(
                    icon: "desktopcomputer",
                    number: "15",
                    unit: "years of your IT budget",
                    emphasis: "Vanished.",
                    audioKey: "comparison_finance_2"
                ),
                ComparisonCard(
                    icon: "person.2.fill",
                    number: "189,000",
                    unit: "client meetings",
                    emphasis: "Lost.",
                    audioKey: "comparison_finance_3"
                )
            ]
        case .supplyChain:
            return [
                ComparisonCard(
                    icon: "person.3.fill",
                    number: "764",
                    unit: "warehouse workers",
                    emphasis: "Not hired.",
                    audioKey: "comparison_supply_1"
                ),
                ComparisonCard(
                    icon: "shippingbox.fill",
                    number: "12,700",
                    unit: "containers",
                    emphasis: "Delayed.",
                    audioKey: "comparison_supply_2"
                ),
                ComparisonCard(
                    icon: "chart.line.downtrend.xyaxis",
                    number: "Your margins.",
                    unit: "Eroded.",
                    emphasis: "Daily.",
                    audioKey: "comparison_supply_3"
                )
            ]
        case .healthcare:
            return [
                ComparisonCard(
                    icon: "cross.fill",
                    number: "1,056",
                    unit: "nurse salaries",
                    emphasis: "Consumed.",
                    audioKey: "comparison_health_1"
                ),
                ComparisonCard(
                    icon: "bed.double.fill",
                    number: "26,400",
                    unit: "patient visits",
                    emphasis: "That didn't happen.",
                    audioKey: "comparison_health_2"
                ),
                ComparisonCard(
                    icon: "brain.head.profile",
                    number: "Your physicians'",
                    unit: "sanity",
                    emphasis: "Under siege.",
                    audioKey: "comparison_health_3"
                )
            ]
        }
    }

    // MARK: - Audio Keys

    static func audioKey(for industry: Industry, phase: AudioPhase) -> String {
        let industryKey = industry.rawValue
        switch phase {
        case .buildingTension:
            return "building_\(industryKey)"
        case .vignette:
            return "vignette_\(industryKey)_enhanced"
        case .suckerPunch:
            return "sucker_punch_\(industryKey)"
        case .comparison(let index):
            return "comparison_\(industryKey)_\(index + 1)"
        }
    }

    enum AudioPhase {
        case buildingTension
        case vignette
        case suckerPunch
        case comparison(Int)
    }
}

// MARK: - Supporting Data Structures

struct SuckerPunchData {
    let amount: Int
    let formattedAmount: String
    let spokenAmount: String
    let audioKey: String
}

struct ComparisonCard: Identifiable {
    let id = UUID()
    let icon: String
    let number: String
    let unit: String
    let emphasis: String
    let audioKey: String
}

// MARK: - Number Formatting

extension Int {
    /// Format large numbers with commas for display
    var formattedWithCommas: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format as currency
    var formattedAsCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}

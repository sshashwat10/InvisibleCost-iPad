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

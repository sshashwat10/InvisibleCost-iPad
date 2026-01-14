import SwiftUI

// MARK: - Department Types

/// Represents the four enterprise process departments for the Invisible Cost experience
/// Replaces the previous Industry enum with process-focused departments per Neeti's feedback
enum Department: String, CaseIterable, Identifiable {
    case p2p = "p2p"                    // Procure-to-Pay
    case o2c = "o2c"                    // Order-to-Cash
    case customerSupport = "customer_support"  // Customer Support
    case itsm = "itsm"                  // IT Service Management

    var id: String { rawValue }

    /// Full display name for UI presentation
    var displayName: String {
        switch self {
        case .p2p: return "PROCURE-TO-PAY"
        case .o2c: return "ORDER-TO-CASH"
        case .customerSupport: return "CUSTOMER SUPPORT"
        case .itsm: return "IT SERVICE MANAGEMENT"
        }
    }

    /// Short name for compact UI elements
    var shortName: String {
        switch self {
        case .p2p: return "P2P"
        case .o2c: return "O2C"
        case .customerSupport: return "Support"
        case .itsm: return "ITSM"
        }
    }

    /// SF Symbol icon for the department
    var icon: String {
        switch self {
        case .p2p: return "cart.fill"
        case .o2c: return "dollarsign.arrow.circlepath"
        case .customerSupport: return "headphones"
        case .itsm: return "server.rack"
        }
    }

    /// Key process description for the department
    var keyProcess: String {
        switch self {
        case .p2p: return "Invoice Processing"
        case .o2c: return "Order Fulfillment"
        case .customerSupport: return "Ticket Resolution"
        case .itsm: return "Incident Management"
        }
    }

    /// Brief description of the department's pain point
    var painDescription: String {
        switch self {
        case .p2p: return "Manual invoice matching, verification, and approval"
        case .o2c: return "Order processing delays and payment collection friction"
        case .customerSupport: return "High ticket volumes and repetitive inquiries"
        case .itsm: return "Password resets and routine troubleshooting"
        }
    }

    /// Color theme for the department
    var theme: DepartmentTheme {
        switch self {
        case .p2p:
            return DepartmentTheme(
                primary: Color(red: 0.23, green: 0.51, blue: 0.96),      // Blue
                accent: Color(red: 0.37, green: 0.62, blue: 1.0),
                glow: Color(red: 0.15, green: 0.35, blue: 0.75),
                gradient: [
                    Color(red: 0.15, green: 0.35, blue: 0.75),
                    Color(red: 0.23, green: 0.51, blue: 0.96)
                ]
            )
        case .o2c:
            return DepartmentTheme(
                primary: Color(red: 0.08, green: 0.72, blue: 0.65),      // Teal
                accent: Color(red: 0.18, green: 0.82, blue: 0.75),
                glow: Color(red: 0.05, green: 0.55, blue: 0.48),
                gradient: [
                    Color(red: 0.05, green: 0.55, blue: 0.48),
                    Color(red: 0.08, green: 0.72, blue: 0.65)
                ]
            )
        case .customerSupport:
            return DepartmentTheme(
                primary: Color(red: 0.96, green: 0.62, blue: 0.04),      // Orange
                accent: Color(red: 1.0, green: 0.72, blue: 0.22),
                glow: Color(red: 0.75, green: 0.45, blue: 0.02),
                gradient: [
                    Color(red: 0.75, green: 0.45, blue: 0.02),
                    Color(red: 0.96, green: 0.62, blue: 0.04)
                ]
            )
        case .itsm:
            return DepartmentTheme(
                primary: Color(red: 0.65, green: 0.35, blue: 0.85),      // Purple
                accent: Color(red: 0.75, green: 0.45, blue: 0.95),
                glow: Color(red: 0.45, green: 0.20, blue: 0.65),
                gradient: [
                    Color(red: 0.45, green: 0.20, blue: 0.65),
                    Color(red: 0.65, green: 0.35, blue: 0.85)
                ]
            )
        }
    }

    /// Benchmark source for the department
    var benchmarkSource: String {
        switch self {
        case .p2p: return "Ardent Partners 2024, APQC"
        case .o2c: return "Hackett Group, APQC, Auxis"
        case .customerSupport: return "HDI, ServiceNow, Gartner"
        case .itsm: return "MetricNet, ServiceNow, Forrester"
        }
    }
}

// MARK: - Department Theme

/// Color theme configuration for a department
struct DepartmentTheme {
    let primary: Color
    let accent: Color
    let glow: Color
    let gradient: [Color]

    /// Secondary text color derived from primary
    var secondaryText: Color {
        primary.opacity(0.7)
    }

    /// Background color for cards
    var cardBackground: Color {
        glow.opacity(0.12)
    }

    /// Border color for cards
    var cardBorder: Color {
        primary.opacity(0.35)
    }
}

// MARK: - Department Content

/// Static content data for each department
struct DepartmentContent {

    // MARK: - Building Tension Content

    static func buildingTensionText(for department: Department) -> (line1: String, line2: String, teaser: String) {
        switch department {
        case .p2p:
            return (
                "Let's take one process... invoice reconciliation.",
                "Every invoice requires matching... verification... approval.",
                "Industry data shows the hidden hours add up fast."
            )
        case .o2c:
            return (
                "Let's examine your order-to-cash cycle.",
                "From order to invoice to payment... every step has friction.",
                "Working capital tied up... waiting. Days stretching into weeks."
            )
        case .customerSupport:
            return (
                "Consider your support operation.",
                "Tickets flowing in... agents stretched thin... routine inquiries piling up.",
                "Countless hours spent on questions that could answer themselves."
            )
        case .itsm:
            return (
                "Look at your IT service desk.",
                "Password resets... basic troubleshooting... the same questions over and over.",
                "Your IT talent is trapped in a cycle of repetitive resolution."
            )
        }
    }

    // MARK: - Vignette Content

    static func vignetteData(for department: Department) -> (title: String, subtitle: String, metrics: [(value: String, label: String)]) {
        switch department {
        case .p2p:
            return (
                title: "PROCURE-TO-PAY",
                subtitle: "Invoice Processing Burden",
                metrics: [
                    ("$9.40", "avg cost/invoice"),
                    ("17.4", "days cycle time"),
                    ("22%", "exception rate")
                ]
            )
        case .o2c:
            return (
                title: "ORDER-TO-CASH",
                subtitle: "Collection Friction",
                metrics: [
                    ("38", "days DSO"),
                    ("3x", "cost vs automated"),
                    ("40%", "error rate")
                ]
            )
        case .customerSupport:
            return (
                title: "CUSTOMER SUPPORT",
                subtitle: "Ticket Overload",
                metrics: [
                    ("$22", "cost per ticket"),
                    ("7-10", "min handle time"),
                    ("70%", "FCR rate")
                ]
            )
        case .itsm:
            return (
                title: "IT SERVICE MGMT",
                subtitle: "Resolution Bottleneck",
                metrics: [
                    ("$22", "Tier-1 cost"),
                    ("$104", "Tier-3 cost"),
                    ("60%", "routine tickets")
                ]
            )
        }
    }

    // MARK: - Comparison Data

    static func comparisonCards(for department: Department, costBreakdown: CostBreakdown) -> [ComparisonCard] {
        let totalCost = costBreakdown.totalCost
        let hours = costBreakdown.annualHours

        switch department {
        case .p2p:
            let fteEquivalent = Int(hours / 2080)
            let projectCount = Int(totalCost / 100_000)
            return [
                ComparisonCard(
                    icon: "person.fill",
                    number: "\(fteEquivalent)",
                    unit: "FTEs processing invoices",
                    emphasis: "Full-time.",
                    audioKey: "comparison_p2p_1"
                ),
                ComparisonCard(
                    icon: "building.2.fill",
                    number: "\(projectCount)",
                    unit: "strategic projects unfunded",
                    emphasis: "Opportunity lost.",
                    audioKey: "comparison_p2p_2"
                ),
                ComparisonCard(
                    icon: "clock.arrow.circlepath",
                    number: "\(Int(hours).formattedWithCommas)",
                    unit: "hours per year",
                    emphasis: "On manual tasks.",
                    audioKey: "comparison_p2p_3"
                )
            ]
        case .o2c:
            let daysRevenue = Int(totalCost / 50_000)
            let cashTiedUp = totalCost * 0.3
            return [
                ComparisonCard(
                    icon: "calendar",
                    number: "\(daysRevenue)",
                    unit: "days of revenue idle",
                    emphasis: "In receivables.",
                    audioKey: "comparison_o2c_1"
                ),
                ComparisonCard(
                    icon: "banknote.fill",
                    number: cashTiedUp.formattedAsCurrency,
                    unit: "working capital tied up",
                    emphasis: "Unavailable.",
                    audioKey: "comparison_o2c_2"
                ),
                ComparisonCard(
                    icon: "arrow.triangle.2.circlepath",
                    number: "\(Int(hours / 40))",
                    unit: "work weeks lost",
                    emphasis: "Every year.",
                    audioKey: "comparison_o2c_3"
                )
            ]
        case .customerSupport:
            let agentEquivalent = Int(hours / 1800)
            let ticketHours = Int(hours)
            return [
                ComparisonCard(
                    icon: "person.wave.2.fill",
                    number: "\(agentEquivalent)",
                    unit: "agents worth of time",
                    emphasis: "On routine queries.",
                    audioKey: "comparison_customer_support_1"
                ),
                ComparisonCard(
                    icon: "clock.fill",
                    number: "\(ticketHours.formattedWithCommas)",
                    unit: "hours handling tickets",
                    emphasis: "AI could resolve.",
                    audioKey: "comparison_customer_support_2"
                ),
                ComparisonCard(
                    icon: "face.smiling.inverse",
                    number: "35-92%",
                    unit: "churn after bad experience",
                    emphasis: "Preventable.",
                    audioKey: "comparison_customer_support_3"
                )
            ]
        case .itsm:
            let passwordResetCost = totalCost * 0.15
            let downtimeHours = Int(hours * 1.5)
            return [
                ComparisonCard(
                    icon: "key.fill",
                    number: passwordResetCost.formattedAsCurrency,
                    unit: "on password resets alone",
                    emphasis: "Automatable.",
                    audioKey: "comparison_itsm_1"
                ),
                ComparisonCard(
                    icon: "hourglass",
                    number: "\(downtimeHours.formattedWithCommas)",
                    unit: "hours of user downtime",
                    emphasis: "Waiting for IT.",
                    audioKey: "comparison_itsm_2"
                ),
                ComparisonCard(
                    icon: "gearshape.2.fill",
                    number: "60%",
                    unit: "of tickets are routine",
                    emphasis: "Could be automated.",
                    audioKey: "comparison_itsm_3"
                )
            ]
        }
    }

    // MARK: - Audio Keys

    static func audioKey(for department: Department, phase: AudioPhase) -> String {
        let deptKey = department.rawValue
        switch phase {
        case .buildingTension:
            return "building_\(deptKey)"
        case .vignette:
            return "vignette_\(deptKey)"
        case .suckerPunch:
            return "sucker_punch_reveal"  // General reveal, numbers shown visually
        case .comparison(let index):
            return "comparison_\(deptKey)_\(index + 1)"
        case .aaValue:
            return "aa_value_\(deptKey)"
        }
    }

    enum AudioPhase {
        case buildingTension
        case vignette
        case suckerPunch
        case comparison(Int)
        case aaValue
    }
}

// MARK: - Comparison Card

struct ComparisonCard: Identifiable {
    let id = UUID()
    let icon: String
    let number: String
    let unit: String
    let emphasis: String
    let audioKey: String
}

// MARK: - Cost Breakdown (Forward Declaration for DepartmentContent)

/// Result of cost calculation - defined in CostCalculator.swift
/// Forward declaration here for DepartmentContent usage
struct CostBreakdown {
    let annualHours: Double
    let directCost: Double
    let indirectCost: Double
    let invisibleCost: Double
    let totalCost: Double
    let department: Department
    let benchmarkSource: String
    let keyMetrics: [KeyMetric]

    static let empty = CostBreakdown(
        annualHours: 0,
        directCost: 0,
        indirectCost: 0,
        invisibleCost: 0,
        totalCost: 0,
        department: .p2p,
        benchmarkSource: "",
        keyMetrics: []
    )
}

struct KeyMetric {
    let label: String
    let value: String
}

# Invisible Cost iPad App - Conceptual Overhaul Plan

**Version:** 2.0
**Date:** January 2026
**Author:** Architecture Council
**Stakeholder:** Neeti

---

## Executive Summary

This document outlines a comprehensive overhaul of the Invisible Cost iPad experience based on Neeti's feedback. The changes shift from emotional, generic storytelling to a **data-driven, personalized cost calculation experience** with specific benchmark citations and clear Automation Anywhere value propositions.

### Key Changes at a Glance

| Aspect | Current State | Target State |
|--------|---------------|--------------|
| Departments | Finance, Healthcare, Supply Chain | **P2P, O2C, Customer Support, ITSM** |
| Narration Style | Generic dramatic statements | **Data-driven with user input references** |
| Cost Display | Fixed "sucker punch" numbers | **Calculated from user input + benchmarks** |
| Value Proposition | Vague "transformation" | **Sourced claims: 262% ROI, 78% cost reduction** |
| Data Sources | None cited | **Hackett, APQC, Ardent Partners, HDI, MetricNet** |

### Core User Inputs (All Departments)

| Input | Description | Used For |
|-------|-------------|----------|
| **Company Name** | User's organization (optional) | Personalization |
| **Number of Employees** | Total employee count | P2P/O2C calculations |
| **Number of Customers Served** | How many customers they support | IT/Support calculations |
| **Avg Size of Customer Orgs** | # employees in customer organizations | IT/Support calculations |

### IT & Customer Support Formula

```
Invisible Cost = Customers Served × Avg Customer Org Size × Cost per Employee
```

Example:
- 500 customers × 1,000 employees/customer × $22/employee = **$11,000,000** invisible cost

---

## Table of Contents

1. [New Department Model](#1-new-department-model)
2. [Benchmark Data Architecture](#2-benchmark-data-architecture)
3. [Cost Calculation Engine](#3-cost-calculation-engine)
4. [New Narration Scripts](#4-new-narration-scripts)
5. [UI/UX Changes](#5-uiux-changes)
6. [Code Architecture Changes](#6-code-architecture-changes)
7. [Implementation Phases](#7-implementation-phases)
8. [File-by-File Changes](#8-file-by-file-changes)
9. [Audio Asset Requirements](#9-audio-asset-requirements)

---

## 1. New Department Model

### 1.1 Department Definitions

Replace the `Industry` enum with a new `Department` enum:

```swift
/// Represents the four enterprise process departments
enum Department: String, CaseIterable, Identifiable {
    case p2p = "p2p"           // Procure-to-Pay
    case o2c = "o2c"           // Order-to-Cash
    case customerSupport = "cs" // Customer Support
    case itsm = "itsm"         // IT Service Management

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .p2p: return "PROCURE-TO-PAY"
        case .o2c: return "ORDER-TO-CASH"
        case .customerSupport: return "CUSTOMER SUPPORT"
        case .itsm: return "IT SERVICE MANAGEMENT"
        }
    }

    var shortName: String {
        switch self {
        case .p2p: return "P2P"
        case .o2c: return "O2C"
        case .customerSupport: return "Support"
        case .itsm: return "ITSM"
        }
    }

    var icon: String {
        switch self {
        case .p2p: return "cart.fill"
        case .o2c: return "dollarsign.arrow.circlepath"
        case .customerSupport: return "headphones"
        case .itsm: return "server.rack"
        }
    }

    var keyProcess: String {
        switch self {
        case .p2p: return "Invoice Processing"
        case .o2c: return "Order Fulfillment"
        case .customerSupport: return "Ticket Resolution"
        case .itsm: return "Incident Management"
        }
    }

    var theme: DepartmentTheme {
        switch self {
        case .p2p:
            return DepartmentTheme(
                primary: Color(red: 0.23, green: 0.51, blue: 0.96),    // Blue
                accent: Color(red: 0.37, green: 0.62, blue: 1.0),
                glow: Color(red: 0.15, green: 0.35, blue: 0.75),
                gradient: [Color(red: 0.15, green: 0.35, blue: 0.75),
                          Color(red: 0.23, green: 0.51, blue: 0.96)]
            )
        case .o2c:
            return DepartmentTheme(
                primary: Color(red: 0.08, green: 0.72, blue: 0.65),    // Teal
                accent: Color(red: 0.18, green: 0.82, blue: 0.75),
                glow: Color(red: 0.05, green: 0.55, blue: 0.48),
                gradient: [Color(red: 0.05, green: 0.55, blue: 0.48),
                          Color(red: 0.08, green: 0.72, blue: 0.65)]
            )
        case .customerSupport:
            return DepartmentTheme(
                primary: Color(red: 0.96, green: 0.62, blue: 0.04),    // Orange
                accent: Color(red: 1.0, green: 0.72, blue: 0.22),
                glow: Color(red: 0.75, green: 0.45, blue: 0.02),
                gradient: [Color(red: 0.75, green: 0.45, blue: 0.02),
                          Color(red: 0.96, green: 0.62, blue: 0.04)]
            )
        case .itsm:
            return DepartmentTheme(
                primary: Color(red: 0.65, green: 0.35, blue: 0.85),    // Purple
                accent: Color(red: 0.75, green: 0.45, blue: 0.95),
                glow: Color(red: 0.45, green: 0.20, blue: 0.65),
                gradient: [Color(red: 0.45, green: 0.20, blue: 0.65),
                          Color(red: 0.65, green: 0.35, blue: 0.85)]
            )
        }
    }
}
```

### 1.2 Department Theme Structure

```swift
struct DepartmentTheme {
    let primary: Color
    let accent: Color
    let glow: Color
    let gradient: [Color]
}
```

---

## 2. Benchmark Data Architecture

### 2.1 Sourced Benchmark Data (2024-2026)

All metrics below are from **credible, published industry studies**. Each figure includes its source citation.

---

### 2.1.1 P2P (Procure-to-Pay) Benchmarks

#### Cost per Invoice

| Performance Tier | Cost | Source |
|------------------|------|--------|
| Top Performers | **$4.98** | APQC |
| Median | **$7.75** | APQC |
| Bottom Performers | **$12.44** | APQC |
| Best-in-Class (Ardent) | **$2.78** | Ardent Partners 2024 |
| Average (Ardent) | **$9.40** | Ardent Partners 2024 |
| Manual (Stampli) | **$7.75** | Stampli |
| Automated (Stampli) | **$2.02** | Stampli |

#### Labor Productivity

| Metric | Value | Source |
|--------|-------|--------|
| Invoices/FTE/year (manual) | **6,082** | Stampli |
| Invoices/FTE/year (automated) | **23,333** | Stampli |
| Forrester/Basware case: AP headcount reduction | **30 → 20 FTEs** (for 450K invoices) | Forrester/Basware TEI |

#### Cycle Time & Accuracy

| Metric | Value | Source |
|--------|-------|--------|
| Cycle time (top performers) | **3.1 days** | Ardent Partners 2024 |
| Cycle time (average) | **17.4 days** | Ardent Partners 2024 |
| Exception rate (best-in-class) | **9%** | Forrester/Basware |
| Exception rate (average) | **22%** | Forrester/Basware |

#### Automation Impact

| Metric | Value | Source |
|--------|-------|--------|
| Cost reduction | **78-81%** | Ardent Partners 2024 |
| Processing speed improvement | **82% faster** | Ardent Partners 2024 |
| 3-year savings (case study) | **$4M** | Forrester/Basware TEI |

**Sources:**
- [APQC - 5 Steps to Lowering AP Processing Cost](https://transformious.com/accounts-payable/5-steps-to-lowering-the-cost-of-ap-processing-and-reducing-transaction-processing-time/)
- [Ardent Partners 2024 ePayables Study](https://www.bottomline.com/resources/blog/ardent-2024-epayables-study-automation-ai-earning-ap-a-seat-at-the-strategy-table)
- [Stampli - P2P KPIs](https://www.stampli.com/blog/accounts-payable/procure-to-pay-kpis/)
- [Forrester/Basware TEI Study](https://tei.forrester.com/go/basware/apautomation/)
- [Ardent Partners AP Metrics 2024](https://www.basware.com/en/resources/ardent-partners-accounts-payable-metrics-that-matter-in-2024)

---

### 2.1.2 O2C (Order-to-Cash) Benchmarks

#### DSO & Collections

| Metric | Value | Source |
|--------|-------|--------|
| DSO (median) | **38 days** | APQC |
| DSO (top performers) | **<30 days** | APQC |
| AI-driven delinquency reduction | **8.4 days** | Hackett Group |
| AI benefits (mid-size firms) | **Up to $7 million** | Hackett Group |

#### Cost & Labor

| Metric | Value | Source |
|--------|-------|--------|
| Cost reduction (automated vs manual) | **3× lower per $1K revenue** | APQC |
| Electronic invoicing (top performers) | **80%** | APQC |
| Auto-applied payments (top performers) | **94%** | APQC |
| Payment application speed (AI) | **50-80% faster** | Grant Thornton, Gartner |

#### Automation Impact

| Metric | Value | Source |
|--------|-------|--------|
| Cycle time improvement | **30-50% faster** | APQC, Hackett |
| Error rate reduction | **20-40%** | APQC, Hackett |
| Invoice processing cost reduction | **79%** | Auxis |
| Handle time reduction | **60%** | Auxis |

**Sources:**
- [Auxis - AR Automation Benefits](https://www.auxis.com/accounts-receivable-automation-benefits-and-best-practices/)
- APQC Benchmarks
- Hackett Group Research

---

### 2.1.3 Customer Support Benchmarks

#### Cost per Ticket

| Metric | Value | Source |
|--------|-------|--------|
| North America average | **$22** | HDI/ServiceNow |
| Range | **$6 - $40** | HDI |
| Cloud/offshore | **<$10** | HDI |
| On-site white-glove | **$40+** | HDI |

#### Labor & Throughput

| Metric | Value | Source |
|--------|-------|--------|
| Average handle time | **7-10 minutes** | Plivo |
| Tickets/month (average center) | **10,700** | HDI |
| Cost saved per hour of reduced AHT | **$20-30** | Industry |

#### Quality Metrics

| Metric | Value | Source |
|--------|-------|--------|
| First Contact Resolution (average) | **70-79%** | Plivo |
| FCR (world-class) | **≥80%** | Plivo |
| Response SLA target | **80% within 20 seconds** | Plivo |
| CSAT (solid performance) | **75-84%** | Plivo |
| Customer churn after bad experiences | **35-92%** | Gartner |

#### Automation Impact

| Metric | Value | Source |
|--------|-------|--------|
| Gartner AI cost savings projection | **$80B by 2026** (~9% drop) | Gartner |
| Cost savings from AI chatbots | **30-50%** | Industry |
| Case study savings | **$120-220K/year** (30-55% less) | Industry |
| Response speed improvement | **50-60% faster** | Pylon |

**Sources:**
- [ServiceNow - Help Desk Statistics 2024](https://www.servicenow.com/products/itsm/help-desk-statistics.html)
- [HDI - State of Tech Support 2025](https://www.thinkhdi.com/library/supportworld/2025/5-insights-hdi-state-of-tech-support-2025)
- [Plivo - Contact Center Benchmarks 2025](https://www.plivo.com/blog/contact-center-statistics-benchmarks-2025/)
- [Pylon - AI Customer Support Guide](https://www.usepylon.com/blog/ai-powered-customer-support-guide)

---

### 2.1.4 ITSM Benchmarks

#### Cost per Ticket

| Tier | Cost | Source |
|------|------|--------|
| Tier-1 | **$22** | MetricNet |
| Tier-3 (escalated) | **$104** | MetricNet |
| General range | **$15-40** | Gartner |

#### Labor & Productivity

| Metric | Value | Source |
|--------|-------|--------|
| Self-service ticket start rate | **60-70%** | Industry |
| Password reset time (manual) | **<15 min** | Industry |
| AI response reduction | **7 hours → near-instant** | Industry survey |

#### SLAs & Cycle Times

| Metric | Value | Source |
|--------|-------|--------|
| Target resolution compliance | **80-90%** | Industry |
| Actual compliance (many orgs) | **60-70%** | Industry |

#### Automation Impact

| Metric | Value | Source |
|--------|-------|--------|
| IT leaders increasing automation spend | **64%** | Netfor |
| AI reduction in repeated questions | **50-60%** | Forrester |
| Response speed improvement | **30-50%** | Forrester |
| Ticket handling speed (automated) | **37-52% faster** | ServiceNow |
| AI ticket volume reduction | **Up to 60%** | ServiceNow |

**Sources:**
- [MetricNet - IT Service Desk Cost](https://www.ghdsi.com/blog/evaluate-reduce-it-service-desk-cost-per-ticket/)
- [ServiceNow - Help Desk Statistics](https://www.servicenow.com/products/itsm/help-desk-statistics.html)
- [Netfor - IT Help Desk Value](https://www.netfor.com/2025/04/02/it-help-desk-support-2/)

---

### 2.1.5 Automation Anywhere Specific (Forrester TEI)

| Metric | Value | Source |
|--------|-------|--------|
| ROI (3-year) | **262%** | Forrester TEI |
| Payback period | **<12 months** | Forrester TEI |
| Total benefits (3-year) | **$13.2 million** | Forrester TEI |
| Staff redeployment savings | **$8.3 million** | Forrester TEI |
| Compliance/audit savings | **$2.7 million** | Forrester TEI |
| Error reduction savings | **$1.1 million** | Forrester TEI |

**Source:** [Forrester TEI Study - Automation Anywhere](https://www.automationanywhere.com/company/blog/company-news/forrester-study-huge-rpa-return-in-short-time-frame)

---

### 2.2 Swift Benchmark Data Model

```swift
/// Industry benchmark data with SOURCED citations (2024-2026)
/// All figures from published analyst/industry studies
struct BenchmarkData {

    // MARK: - P2P (Procure-to-Pay) Benchmarks
    // Sources: APQC, Ardent Partners 2024, Stampli, Forrester/Basware TEI

    struct P2P {
        /// Cost per invoice by performance tier
        struct CostPerInvoice {
            static let topPerformers = 4.98      // APQC
            static let median = 7.75             // APQC
            static let bottomPerformers = 12.44  // APQC
            static let bestInClass = 2.78        // Ardent Partners 2024
            static let average = 9.40            // Ardent Partners 2024
            static let manual = 7.75             // Stampli
            static let automated = 2.02          // Stampli
        }

        /// Invoices per FTE per year
        struct Productivity {
            static let manual = 6082             // Stampli
            static let automated = 23333         // Stampli
        }

        /// Cycle time in days
        struct CycleTime {
            static let topPerformers = 3.1       // Ardent Partners 2024
            static let average = 17.4            // Ardent Partners 2024
        }

        /// Exception rates
        struct ExceptionRate {
            static let bestInClass = 0.09        // 9% - Forrester/Basware
            static let average = 0.22            // 22% - Forrester/Basware
        }

        /// Automation impact percentages
        struct AutomationImpact {
            static let costReduction = 0.78...0.81      // 78-81% - Ardent Partners
            static let speedImprovement = 0.82          // 82% faster - Ardent Partners
        }

        static let sources = [
            "APQC",
            "Ardent Partners 2024 ePayables Study",
            "Stampli P2P KPIs",
            "Forrester/Basware TEI Study"
        ]
    }

    // MARK: - O2C (Order-to-Cash) Benchmarks
    // Sources: APQC, Hackett Group, Auxis, Grant Thornton, Gartner

    struct O2C {
        /// Days Sales Outstanding
        struct DSO {
            static let median = 38               // APQC
            static let topPerformers = 30        // APQC (< 30)
            static let aiReduction = 8.4         // Hackett Group (days reduced)
        }

        /// Automation impact
        struct AutomationImpact {
            static let costReductionVsManual = 3.0      // 3x lower - APQC
            static let electronicInvoicing = 0.80       // 80% - APQC top performers
            static let autoAppliedPayments = 0.94       // 94% - APQC top performers
            static let paymentAppSpeedImprovement = 0.50...0.80  // 50-80% faster - Grant Thornton
            static let cycleTimeImprovement = 0.30...0.50        // 30-50% faster - APQC/Hackett
            static let errorRateReduction = 0.20...0.40          // 20-40% - APQC/Hackett
            static let invoiceCostReduction = 0.79               // 79% - Auxis
            static let handleTimeReduction = 0.60                // 60% - Auxis
        }

        /// AI benefits
        struct AIBenefits {
            static let midSizeFirmBenefits = 7_000_000  // Up to $7M - Hackett Group
        }

        static let sources = [
            "APQC",
            "Hackett Group",
            "Auxis AR Automation Study",
            "Grant Thornton",
            "Gartner"
        ]
    }

    // MARK: - Customer Support Benchmarks
    // Sources: HDI, ServiceNow, Plivo, Gartner, Pylon

    struct CustomerSupport {
        /// Cost per ticket
        struct CostPerTicket {
            static let northAmericaAverage = 22.0    // HDI/ServiceNow
            static let range = 6.0...40.0            // HDI
            static let cloudOffshore = 10.0          // < $10 - HDI
            static let whiteGlove = 40.0             // $40+ - HDI
        }

        /// Handle time and throughput
        struct Labor {
            static let avgHandleTimeMinutes = 7.0...10.0  // Plivo
            static let ticketsPerMonthAvgCenter = 10700   // HDI
            static let costPerHourSaved = 20.0...30.0     // Industry
        }

        /// Quality metrics
        struct Quality {
            static let fcrAverage = 0.70...0.79      // 70-79% - Plivo
            static let fcrWorldClass = 0.80          // ≥80% - Plivo
            static let csatSolid = 0.75...0.84       // 75-84% - Plivo
            static let churnAfterBadExperience = 0.35...0.92  // 35-92% - Gartner
        }

        /// Automation impact
        struct AutomationImpact {
            static let gartnerAICostSavings2026 = 80_000_000_000  // $80B - Gartner
            static let chatbotCostSavings = 0.30...0.50           // 30-50%
            static let responseSpeedImprovement = 0.50...0.60     // 50-60% faster - Pylon
        }

        static let sources = [
            "HDI State of Tech Support 2025",
            "ServiceNow Help Desk Statistics 2024",
            "Plivo Contact Center Benchmarks 2025",
            "Gartner",
            "Pylon AI Customer Support Guide"
        ]
    }

    // MARK: - ITSM Benchmarks
    // Sources: MetricNet, ServiceNow, Netfor, Forrester, Gartner

    struct ITSM {
        /// Cost per ticket by tier
        struct CostPerTicket {
            static let tier1 = 22.0              // MetricNet
            static let tier3Escalated = 104.0   // MetricNet
            static let generalRange = 15.0...40.0  // Gartner
        }

        /// Automation impact
        struct AutomationImpact {
            static let itLeadersIncreasingSpend = 0.64       // 64% - Netfor
            static let aiRepeatedQuestionReduction = 0.50...0.60  // 50-60% - Forrester
            static let responseSpeedImprovement = 0.30...0.50     // 30-50% - Forrester
            static let ticketHandlingSpeed = 0.37...0.52          // 37-52% faster - ServiceNow
            static let aiTicketVolumeReduction = 0.60             // Up to 60% - ServiceNow
        }

        static let sources = [
            "MetricNet",
            "ServiceNow Help Desk Statistics",
            "Netfor IT Help Desk Value Study",
            "Forrester",
            "Gartner"
        ]
    }

    // MARK: - Automation Anywhere Specific (Forrester TEI Study)

    struct AutomationAnywhere {
        static let roiThreeYear = 2.62               // 262%
        static let paybackMonths = 12                // < 12 months
        static let totalBenefitsThreeYear = 13_200_000  // $13.2M
        static let staffRedeploymentSavings = 8_300_000  // $8.3M
        static let complianceAuditSavings = 2_700_000    // $2.7M
        static let errorReductionSavings = 1_100_000     // $1.1M

        static let source = "Forrester Total Economic Impact Study"
        static let sourceURL = "https://www.automationanywhere.com/company/blog/company-news/forrester-study-huge-rpa-return-in-short-time-frame"
    }
}
```

### 2.3 Full Citation List (USA-Based Sources)

| # | Source | URL | Used For |
|---|--------|-----|----------|
| 1 | APQC via Transformious | https://transformious.com/accounts-payable/5-steps-to-lowering-the-cost-of-ap-processing-and-reducing-transaction-processing-time/ | P2P cost per invoice |
| 2 | Ardent Partners 2024 ePayables | https://www.bottomline.com/resources/blog/ardent-2024-epayables-study-automation-ai-earning-ap-a-seat-at-the-strategy-table | P2P automation impact |
| 3 | Stampli P2P KPIs | https://www.stampli.com/blog/accounts-payable/procure-to-pay-kpis/ | P2P productivity |
| 4 | Forrester/Basware TEI | https://tei.forrester.com/go/basware/apautomation/ | P2P case study |
| 5 | Ardent Partners AP Metrics 2024 | https://www.basware.com/en/resources/ardent-partners-accounts-payable-metrics-that-matter-in-2024 | P2P cycle times |
| 6 | Auxis AR Automation | https://www.auxis.com/accounts-receivable-automation-benefits-and-best-practices/ | O2C metrics |
| 7 | MetricNet via GHDSI | https://www.ghdsi.com/blog/evaluate-reduce-it-service-desk-cost-per-ticket/ | ITSM cost per ticket |
| 8 | ServiceNow Help Desk Stats | https://www.servicenow.com/products/itsm/help-desk-statistics.html | ITSM, Support metrics |
| 9 | Plivo Contact Center 2025 | https://www.plivo.com/blog/contact-center-statistics-benchmarks-2025/ | Customer Support |
| 10 | HDI State of Tech Support 2025 | https://www.thinkhdi.com/library/supportworld/2025/5-insights-hdi-state-of-tech-support-2025 | Support benchmarks |
| 11 | Pylon AI Support Guide | https://www.usepylon.com/blog/ai-powered-customer-support-guide | AI response times |
| 12 | Netfor IT Help Desk | https://www.netfor.com/2025/04/02/it-help-desk-support-2/ | ITSM automation |
| 13 | Forrester TEI - Automation Anywhere | https://www.automationanywhere.com/company/blog/company-news/forrester-study-huge-rpa-return-in-short-time-frame | AA ROI |

---

## 3. Cost Calculation Engine

### 3.1 User Input Model (Updated per Neeti)

**Core Inputs Required for ALL Departments:**

| Input | Description | Example |
|-------|-------------|---------|
| **Company Name** | User's organization | "Acme Corp" |
| **Number of Employees** | Total employee count | 5,000 |
| **Number of Customers Served** | How many customers they support | 500 |
| **Average Size of Customer Orgs** | # of employees in customer organizations | 1,000 |

**Calculation Formula for IT & Customer Support:**
```
Invisible Cost = Customers Served × Avg Customer Org Size × Cost per Employee
```

```swift
/// User input data for cost calculation
struct UserInputData {
    // ===========================================
    // CORE INPUTS (Required for ALL departments)
    // ===========================================

    /// Company name (optional, for personalization)
    var companyName: String = ""

    /// Number of employees in user's organization
    var employeeCount: Int = 100

    /// Number of customers the user serves/supports
    var customersServed: Int = 100

    /// Average size (# employees) of customer organizations
    var avgCustomerOrgSize: Int = 500

    /// Selected department
    var department: Department = .p2p

    // ===========================================
    // DEPARTMENT-SPECIFIC INPUTS
    // ===========================================

    var p2pData: P2PInput?
    var o2cData: O2CInput?
    var customerSupportData: CustomerSupportInput?
    var itsmData: ITSMInput?

    // ===========================================
    // RATE DATA
    // ===========================================

    /// Loaded cost per hour (default $75)
    var averageHourlyRate: Double = 75.0

    /// Overhead/indirect cost multiplier (default 2.5x)
    var overheadMultiplier: Double = 2.5

    // ===========================================
    // COMPUTED: Total Customer Employee Base
    // ===========================================

    /// For IT/Support calculations: total employees across all customers
    var totalCustomerEmployees: Int {
        return customersServed * avgCustomerOrgSize
    }
}

// ===========================================
// P2P-SPECIFIC INPUTS
// ===========================================
struct P2PInput {
    var invoicesPerMonth: Int = 5000
    var currentAutomationLevel: BenchmarkData.AutomationLevel = .manual
    var fteCount: Int = 10
}

// ===========================================
// O2C-SPECIFIC INPUTS
// ===========================================
struct O2CInput {
    var ordersPerMonth: Int = 10000
    var currentDSO: Int = 55
    var fteCount: Int = 15
}

// ===========================================
// CUSTOMER SUPPORT INPUTS
// Uses: customersServed × avgCustomerOrgSize × costPerEmployee
// ===========================================
struct CustomerSupportInput {
    /// Cost per employee served (benchmark: varies by channel)
    var costPerEmployeeServed: Double = 22.0  // HDI benchmark
    var currentChannel: BenchmarkData.SupportChannel = .phone
    var agentCount: Int = 50
}

// ===========================================
// ITSM INPUTS
// Uses: customersServed × avgCustomerOrgSize × costPerEmployee
// ===========================================
struct ITSMInput {
    /// Cost per employee supported (benchmark: $22 Tier-1, $104 Tier-3)
    var costPerEmployeeSupported: Double = 22.0  // MetricNet benchmark
    var itStaffCount: Int = 25
    var passwordResetsPerMonth: Int = 1000
}
```

### 3.2 Cost Calculator

```swift
/// Calculates invisible costs based on user input and benchmarks
struct CostCalculator {

    let userInput: UserInputData

    // MARK: - Main Calculation

    func calculateInvisibleCost() -> CostBreakdown {
        switch userInput.department {
        case .p2p:
            return calculateP2PCost()
        case .o2c:
            return calculateO2CCost()
        case .customerSupport:
            return calculateSupportCost()
        case .itsm:
            return calculateITSMCost()
        }
    }

    // MARK: - P2P Calculation

    private func calculateP2PCost() -> CostBreakdown {
        guard let input = userInput.p2pData else {
            return CostBreakdown.empty
        }

        let annualInvoices = input.invoicesPerMonth * 12

        // Current cost (using midpoint of range)
        let currentCostPerInvoice = BenchmarkData.P2P.costPerInvoice[input.currentAutomationLevel]!
        let avgCurrentCost = (currentCostPerInvoice.lowerBound + currentCostPerInvoice.upperBound) / 2

        // Hours calculation
        let hoursPerThousand = BenchmarkData.P2P.hoursPerThousandInvoices[input.currentAutomationLevel]!
        let annualHours = (Double(annualInvoices) / 1000.0) * hoursPerThousand

        // Direct labor cost
        let directCost = annualHours * userInput.averageHourlyRate

        // Indirect/overhead cost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)

        // Total processing cost
        let totalProcessingCost = Double(annualInvoices) * avgCurrentCost

        // Invisible cost = opportunity cost + exception handling + rework
        let exceptionRate = BenchmarkData.P2P.exceptionRate[input.currentAutomationLevel]!
        let exceptionCost = totalProcessingCost * exceptionRate * 2.0 // Exceptions cost 2x to handle

        let invisibleCost = indirectCost + exceptionCost

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: directCost + indirectCost + invisibleCost,
            department: .p2p,
            benchmarkSource: BenchmarkData.P2P.source,
            keyMetrics: [
                KeyMetric(label: "Invoices/Year", value: annualInvoices.formattedWithCommas),
                KeyMetric(label: "Hours of Processing", value: Int(annualHours).formattedWithCommas),
                KeyMetric(label: "Cost per Invoice", value: avgCurrentCost.formattedAsCurrency)
            ]
        )
    }

    // MARK: - O2C Calculation

    private func calculateO2CCost() -> CostBreakdown {
        guard let input = userInput.o2cData else {
            return CostBreakdown.empty
        }

        let annualOrders = input.ordersPerMonth * 12

        // Calculate based on automation level inferred from DSO
        let automationLevel: BenchmarkData.AutomationLevel = {
            if input.currentDSO > 55 { return .manual }
            if input.currentDSO > 40 { return .partial }
            if input.currentDSO > 28 { return .high }
            return .aiAugmented
        }()

        let costRange = BenchmarkData.O2C.costPerOrder[automationLevel]!
        let avgCostPerOrder = (costRange.lowerBound + costRange.upperBound) / 2

        // Direct cost of order processing
        let directCost = Double(annualOrders) * avgCostPerOrder

        // Calculate cash flow impact from DSO
        // Higher DSO = more working capital tied up
        let dailyRevenue = (Double(annualOrders) * 100) / 365 // Assume $100 avg order value
        let cashTiedUp = dailyRevenue * Double(input.currentDSO)
        let workingCapitalCost = cashTiedUp * 0.08 // 8% cost of capital

        // Error-related costs
        let errorRate = BenchmarkData.O2C.orderErrorRate[automationLevel]!
        let errorCost = Double(annualOrders) * errorRate * 50 // $50 per error to fix

        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)
        let invisibleCost = workingCapitalCost + errorCost + indirectCost

        let annualHours = Double(input.fteCount) * 2080 * 0.7 // 70% of FTE time on O2C

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: directCost + invisibleCost,
            department: .o2c,
            benchmarkSource: BenchmarkData.O2C.source,
            keyMetrics: [
                KeyMetric(label: "Orders/Year", value: annualOrders.formattedWithCommas),
                KeyMetric(label: "Days Sales Outstanding", value: "\(input.currentDSO) days"),
                KeyMetric(label: "Working Capital Impact", value: workingCapitalCost.formattedAsCurrency)
            ]
        )
    }

    // MARK: - Customer Support Calculation
    // FORMULA: Customers Served × Avg Customer Org Size × Cost per Employee

    private func calculateSupportCost() -> CostBreakdown {
        guard let input = userInput.customerSupportData else {
            return CostBreakdown.empty
        }

        // ===========================================
        // CORE CALCULATION (per Neeti's formula)
        // Customers Served × Avg Org Size × Cost/Employee
        // ===========================================

        let totalEmployeesServed = userInput.totalCustomerEmployees  // customersServed × avgCustomerOrgSize
        let costPerEmployee = input.costPerEmployeeServed            // $22 benchmark (HDI)

        // Base invisible cost from serving customer employees
        let baseCost = Double(totalEmployeesServed) * costPerEmployee

        // Additional costs based on channel efficiency
        let costRange = BenchmarkData.CustomerSupport.costPerTicket[input.currentChannel]!
        let avgCostPerTicket = (costRange.lowerBound + costRange.upperBound) / 2

        // Estimate tickets based on employee base (roughly 0.5 tickets/employee/year)
        let estimatedAnnualTickets = Double(totalEmployeesServed) * 0.5

        let automationLevel: BenchmarkData.AutomationLevel = {
            switch input.currentChannel {
            case .phone, .email: return .manual
            case .chat: return .partial
            case .selfService: return .high
            case .aiAssisted: return .aiAugmented
            }
        }()

        let avgHandleTime = BenchmarkData.CustomerSupport.avgHandleTime[automationLevel]!
        let annualHours = (estimatedAnnualTickets * avgHandleTime) / 60.0

        let directCost = baseCost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)

        // FCR impact
        let fcr = BenchmarkData.CustomerSupport.firstContactResolution[automationLevel]!
        let repeatCost = estimatedAnnualTickets * (1.0 - fcr) * avgCostPerTicket * 1.5

        let invisibleCost = indirectCost + repeatCost

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: directCost + invisibleCost,
            department: .customerSupport,
            benchmarkSource: BenchmarkData.CustomerSupport.source,
            keyMetrics: [
                KeyMetric(label: "Customers Served", value: userInput.customersServed.formattedWithCommas),
                KeyMetric(label: "Avg Customer Org Size", value: userInput.avgCustomerOrgSize.formattedWithCommas),
                KeyMetric(label: "Total Employees Supported", value: totalEmployeesServed.formattedWithCommas),
                KeyMetric(label: "Cost per Employee", value: costPerEmployee.formattedAsCurrency)
            ]
        )
    }

    // MARK: - ITSM Calculation
    // FORMULA: Customers Served × Avg Customer Org Size × Cost per Employee

    private func calculateITSMCost() -> CostBreakdown {
        guard let input = userInput.itsmData else {
            return CostBreakdown.empty
        }

        // ===========================================
        // CORE CALCULATION (per Neeti's formula)
        // Customers Served × Avg Org Size × Cost/Employee
        // ===========================================

        let totalEmployeesSupported = userInput.totalCustomerEmployees  // customersServed × avgCustomerOrgSize
        let costPerEmployee = input.costPerEmployeeSupported            // $22 Tier-1 (MetricNet)

        // Base invisible cost from supporting customer employees
        let baseCost = Double(totalEmployeesSupported) * costPerEmployee

        // Estimate incidents based on employee base (roughly 2 incidents/employee/year)
        let estimatedAnnualIncidents = Double(totalEmployeesSupported) * 2.0

        // Password resets (roughly 10% of employee base per year)
        let estimatedPasswordResets = Double(totalEmployeesSupported) * 0.10

        // Determine automation level
        let incidentsPerStaff = estimatedAnnualIncidents / (Double(input.itStaffCount) * 12)
        let automationLevel: BenchmarkData.AutomationLevel = {
            if incidentsPerStaff < 160 { return .manual }
            if incidentsPerStaff < 220 { return .partial }
            if incidentsPerStaff < 380 { return .high }
            return .aiAugmented
        }()

        let mttr = BenchmarkData.ITSM.meanTimeToResolve[automationLevel]!
        let passwordResetCost = BenchmarkData.ITSM.passwordResetCost[automationLevel]!

        // Password reset cost (major hidden cost)
        let passwordTotalCost = estimatedPasswordResets * passwordResetCost

        // Downtime/productivity loss
        let avgUsersAffected = 5.0
        let productivityLoss = estimatedAnnualIncidents * mttr * avgUsersAffected * (userInput.averageHourlyRate / 2)

        let directCost = baseCost + passwordTotalCost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)
        let invisibleCost = productivityLoss + indirectCost

        let annualHours = estimatedAnnualIncidents * mttr

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: directCost + invisibleCost,
            department: .itsm,
            benchmarkSource: BenchmarkData.ITSM.source,
            keyMetrics: [
                KeyMetric(label: "Customers Served", value: userInput.customersServed.formattedWithCommas),
                KeyMetric(label: "Avg Customer Org Size", value: userInput.avgCustomerOrgSize.formattedWithCommas),
                KeyMetric(label: "Total Employees Supported", value: totalEmployeesSupported.formattedWithCommas),
                KeyMetric(label: "Cost per Employee", value: costPerEmployee.formattedAsCurrency)
            ]
        )
    }
}

/// Result of cost calculation
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
```

### 3.3 Automation Anywhere Savings Calculator (SOURCED)

All projections below use **published, sourced benchmarks only**.

```swift
/// Calculates potential savings with Automation Anywhere
/// All figures based on published industry research
struct SavingsCalculator {

    let currentCost: CostBreakdown

    /// Best-in-class automation savings projection
    /// Source: Ardent Partners 2024 ePayables Study (78-81% cost reduction)
    var automationSavings: SavingsProjection {
        // Using conservative end of 78-81% range
        let targetReduction = 0.78
        let annualSavings = currentCost.totalCost * targetReduction

        return SavingsProjection(
            reductionPercentage: 78,
            annualSavings: annualSavings,
            hoursSaved: currentCost.annualHours * targetReduction,
            source: "Ardent Partners 2024 ePayables Study",
            sourceURL: "https://www.bottomline.com/resources/blog/ardent-2024-epayables-study-automation-ai-earning-ap-a-seat-at-the-strategy-table"
        )
    }

    /// ROI projection based on Forrester TEI Study
    /// Source: Forrester Total Economic Impact Study - Automation Anywhere
    var roiProjection: ROIProjection {
        return ROIProjection(
            threeYearROI: 262,           // 262% ROI
            paybackMonths: 12,           // < 12 months
            threeYearBenefits: 13_200_000, // $13.2M
            source: "Forrester Total Economic Impact Study",
            sourceURL: "https://www.automationanywhere.com/company/blog/company-news/forrester-study-huge-rpa-return-in-short-time-frame"
        )
    }

    /// Department-specific savings based on published benchmarks
    func departmentSpecificSavings() -> DepartmentSavings {
        switch currentCost.department {
        case .p2p:
            // Ardent Partners 2024: 78-81% cost reduction, 82% faster
            return DepartmentSavings(
                costReduction: "78-81%",
                speedImprovement: "82% faster",
                cycleTimeFrom: "17.4 days",
                cycleTimeTo: "3.1 days",
                source: "Ardent Partners 2024"
            )
        case .o2c:
            // Auxis: 79% invoice cost reduction, 60% handle time reduction
            return DepartmentSavings(
                costReduction: "79%",
                speedImprovement: "60% faster",
                cycleTimeFrom: "38 days DSO",
                cycleTimeTo: "<30 days DSO",
                source: "Auxis, APQC, Hackett Group"
            )
        case .customerSupport:
            // Gartner: $80B savings by 2026, 30-50% chatbot savings
            return DepartmentSavings(
                costReduction: "30-50%",
                speedImprovement: "50-60% faster",
                cycleTimeFrom: "7-10 min handle time",
                cycleTimeTo: "Near-instant AI response",
                source: "Gartner, HDI, Pylon"
            )
        case .itsm:
            // ServiceNow: 60% ticket volume reduction, 37-52% faster
            return DepartmentSavings(
                costReduction: "Up to 60%",
                speedImprovement: "37-52% faster",
                cycleTimeFrom: "Manual resolution",
                cycleTimeTo: "AI-assisted resolution",
                source: "ServiceNow, MetricNet"
            )
        }
    }
}

struct SavingsProjection {
    let reductionPercentage: Int
    let annualSavings: Double
    let hoursSaved: Double
    let source: String
    let sourceURL: String

    var formattedSavings: String {
        annualSavings.formattedAsCurrency
    }

    var formattedHours: String {
        Int(hoursSaved).formattedWithCommas
    }
}

struct ROIProjection {
    let threeYearROI: Int           // Percentage
    let paybackMonths: Int          // Months
    let threeYearBenefits: Double   // Dollar amount
    let source: String
    let sourceURL: String
}

struct DepartmentSavings {
    let costReduction: String
    let speedImprovement: String
    let cycleTimeFrom: String
    let cycleTimeTo: String
    let source: String
}
```

---

## 4. New Narration Scripts

### 4.1 Opening Narrations (Unchanged)

```swift
// Keep existing emotional opening
"opening_1": "Every organization... carries a hidden cost.",
"opening_2": "Most leaders... never see it.",
```

### 4.2 Department Selection Narration

```swift
"choose_department": "Choose your department to begin."
```

### 4.3 Personal Input Narration

```swift
"personal_input": "Let's calculate your hidden cost. Tell us about your organization."
```

### 4.4 Building Tension - P2P (Procure-to-Pay)

```swift
"building_p2p": """
Let's take one process... invoice reconciliation.
Every invoice requires matching... verification... approval.
Industry data shows the hidden hours add up fast.
That's not just time... it's talent locked away from strategic work.
"""
```

**Note:** Specific numbers (hours, costs) are shown visually on screen - narration stays general.

### 4.5 Building Tension - O2C (Order-to-Cash)

```swift
"building_o2c": """
Let's examine your order-to-cash cycle.
From order to invoice to payment... every step has friction.
Working capital tied up... waiting. Days stretching into weeks.
Every day that number sits there... is money that could be building your future.
"""
```

**Note:** Specific DSO, cash amounts shown visually on screen - narration stays general.

### 4.6 Building Tension - Customer Support

```swift
"building_cs": """
Consider your support operation.
Tickets flowing in... agents stretched thin... routine inquiries piling up.
Your team spends countless hours on questions that could answer themselves.
Hours that could be spent on the interactions that actually build loyalty.
"""
```

**Note:** Specific ticket counts, hours shown visually on screen - narration stays general.

### 4.7 Building Tension - ITSM

```swift
"building_itsm": """
Look at your IT service desk.
Password resets... basic troubleshooting... the same questions over and over.
Your IT talent is trapped in a cycle of repetitive resolution.
Each manual task is a barrier between your team and innovation.
"""
```

**Note:** Specific incident counts, costs shown visually on screen - narration stays general.

### 4.8 Vignette Narrations (Concise)

```swift
"vignette_p2p": "Hours... lost... to matching invoices machines were built to handle.",
"vignette_o2c": "Cash flow... delayed... by processes that should be instant.",
"vignette_cs": "Agents... drowning... in tickets AI could resolve in seconds.",
"vignette_itsm": "Engineers... reduced... to password reset specialists."
```

### 4.9 Pattern Break

```swift
"pattern_break": "But what if... you could see the real number?"
```

### 4.10 Sucker Punch Reveal (Data-Driven)

The numbers are now calculated, not hard-coded. The narration template:

```swift
// Template for dynamic narration
func suckerPunchNarration(cost: CostBreakdown) -> String {
    let formatted = cost.totalCost.formattedSpoken // "two point four million"
    return """
    \(formatted) dollars.
    That's your invisible cost.
    {directCost} in direct labor.
    {indirectCost} in overhead and loaded costs.
    And over {invisibleCost}... in costs you never see on a spreadsheet.
    """
}
```

**Audio Recording Approach:**
Since exact numbers vary by user, we have two options:

1. **Dynamic TTS:** Use high-quality text-to-speech for the number portions
2. **Modular Recording:** Record number components separately and assemble
3. **General Narration:** Keep narration general, show specific numbers visually

**Recommended Approach (Option 3):**

```swift
"sucker_punch_reveal": """
Look at that number.
Direct costs. Indirect costs. And the invisible cost you never see on a spreadsheet.
This is real money. Your money. Every single year.
"""
```

The specific numbers ($X in direct, $Y in indirect, $Z invisible) display visually on screen with animations, while the narration provides emotional context.

### 4.11 Automation Anywhere Value Proposition (SOURCED)

**NOTE:** All claims below are backed by published research.

```swift
// Option 1: Forrester TEI Study (AA-specific)
"aa_value_forrester": """
Two hundred sixty-two percent ROI... over three years.
Payback in under twelve months.
Forrester studied five global enterprises. This is what they found.
"""
// Source: Forrester Total Economic Impact Study

// Option 2: P2P-specific (Ardent Partners)
"aa_value_p2p": """
From twelve dollars an invoice... to two.
From seventeen days... to three.
Seventy-eight percent lower costs. Eighty-two percent faster.
Based on Ardent Partners' twenty twenty-four ePayables study.
"""
// Source: Ardent Partners 2024 ePayables Study

// Option 3: General automation impact
"aa_value_general": """
Best-in-class automation delivers seventy-eight to eighty-one percent lower processing costs.
Not marketing. Published benchmarks from Ardent Partners.
"""
// Source: Ardent Partners 2024

// Option 4: Productivity focus
"aa_value_productivity": """
Six thousand invoices per person... becomes twenty-three thousand.
Four times the throughput. Same team.
Documented by Stampli and Forrester.
"""
// Source: Stampli P2P KPIs, Forrester/Basware TEI

// Option 5: ITSM-specific
"aa_value_itsm": """
Ticket volume reduced by sixty percent.
Resolution thirty-seven to fifty-two percent faster.
ServiceNow's research. Not ours.
"""
// Source: ServiceNow Help Desk Statistics 2024

// Option 6: Customer Support
"aa_value_support": """
Eighty billion dollars in service costs... cut by twenty twenty-six.
Gartner's projection. AI is changing everything.
"""
// Source: Gartner
```

**REMOVED (Unsourced):**
- ~~"50% in 6 months"~~ - No credible source
- ~~"80% in 9 months"~~ - No credible source
- ~~"Not a promise. A proven pattern."~~ - Marketing fluff

### 4.12 Comparison Narrations (Department-Specific)

These should reference relatable equivalents to the calculated cost.

```swift
// P2P Comparisons
"comparison_p2p_1": "That's {fteEquivalent} full-time employees... doing nothing but processing invoices.",
"comparison_p2p_2": "{yearsOfIT} years of your IT budget... vanished.",
"comparison_p2p_3": "{strategicProjects} strategic projects... that never happened."

// O2C Comparisons
"comparison_o2c_1": "That's {daysOfRevenue} days of revenue... sitting idle in receivables.",
"comparison_o2c_2": "{lostDeals} potential deals... unfunded due to cash constraints.",
"comparison_o2c_3": "Your competitors with faster O2C... they're investing this back. Daily."

// Customer Support Comparisons
"comparison_cs_1": "{agentHours} hours of agent time... consumed by questions AI could answer instantly.",
"comparison_cs_2": "{customerExperiences} frustrated customers... who waited when they didn't have to.",
"comparison_cs_3": "Your CSAT score could be {csatImprovement} points higher. Today."

// ITSM Comparisons
"comparison_itsm_1": "That's {passwordCost} spent on password resets alone.",
"comparison_itsm_2": "{downtimeHours} hours of employee downtime... waiting for IT.",
"comparison_itsm_3": "Your engineers could be building. Instead, they're resetting."
```

### 4.13 Human Return & CTA

```swift
"restoration": "The chains dissolve... one by one.",
"breathe": "Breathe... this is what's possible.",
"purpose": "Strategy... not spreadsheets. Innovation... not administration. Leading... not chasing.",
"final_cta": "The invisible cost... ends now. The choice is yours."
```

---

## 5. UI/UX Changes

### 5.1 Department Selection Screen

**Current:** Three industry cards (Finance, Healthcare, Supply Chain)
**New:** Four department cards with process-focused messaging

```
+--------------------------------------------------+
|                                                  |
|        "CHOOSE YOUR DEPARTMENT"                  |
|                                                  |
|   +----------+  +----------+  +----------+       |
|   |   P2P    |  |   O2C    |  | Support  |       |
|   | Procure  |  | Order    |  | Customer |       |
|   | to Pay   |  | to Cash  |  | Support  |       |
|   +----------+  +----------+  +----------+       |
|                                                  |
|                 +----------+                     |
|                 |   ITSM   |                     |
|                 |   IT Svc |                     |
|                 |   Mgmt   |                     |
|                 +----------+                     |
|                                                  |
+--------------------------------------------------+
```

### 5.2 Enhanced Personal Input Screen

**Core Inputs (Required for ALL Departments):**

```
+--------------------------------------------------+
|                                                  |
|      "LET'S CALCULATE YOUR HIDDEN COST"          |
|                                                  |
|  +--------------------------------------------+  |
|  | ABOUT YOUR ORGANIZATION                    |  |
|  |                                            |  |
|  | Company Name (optional):                   |  |
|  | [_______________]                          |  |
|  |                                            |  |
|  | Number of Employees:                       |  |
|  | [100] [500] [1K] [5K] [10K+]              |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|  +--------------------------------------------+  |
|  | CUSTOMERS YOU SERVE                        |  |
|  |                                            |  |
|  | Number of Customers:                       |  |
|  | [10] [50] [100] [500] [1K+]               |  |
|  |                                            |  |
|  | Avg Size of Customer Orgs (employees):     |  |
|  | [100] [500] [1K] [5K] [10K+]              |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
+--------------------------------------------------+
```

**P2P/O2C Additional Inputs:**

```
+--------------------------------------------------+
|  +--------------------------------------------+  |
|  | P2P-SPECIFIC INPUTS                        |  |
|  |                                            |  |
|  | Invoices per Month:                        |  |
|  | [1K] [5K] [10K] [25K] [50K+]               |  |
|  |                                            |  |
|  | AP Team Size:                              |  |
|  | [______] FTEs                              |  |
|  |                                            |  |
|  | Current Automation:                        |  |
|  | [ ] Manual  [ ] Partial  [ ] Automated     |  |
|  |                                            |  |
|  +--------------------------------------------+  |
+--------------------------------------------------+
```

**IT/Customer Support Input (Uses Core Formula):**

```
+--------------------------------------------------+
|  +--------------------------------------------+  |
|  | IT/SUPPORT CALCULATION                     |  |
|  |                                            |  |
|  | Based on your inputs:                      |  |
|  |                                            |  |
|  | Customers Served:        500               |  |
|  | × Avg Customer Org Size: 1,000 employees   |  |
|  | = Total Employees Supported: 500,000       |  |
|  |                                            |  |
|  | × Cost per Employee: $22 (HDI benchmark)   |  |
|  |                                            |  |
|  | = Base Cost: $11,000,000                   |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|  +--------------------------------------------+  |
|  | YOUR ESTIMATED INVISIBLE COST              |  |
|  |                                            |  |
|  |        $11,000,000 / year                  |  |
|  |                                            |  |
|  | Source: HDI/MetricNet benchmarks           |  |
|  +--------------------------------------------+  |
|                                                  |
|              [ See Your Impact ]                 |
|                                                  |
+--------------------------------------------------+
```

### 5.3 Sucker Punch Reveal - Cost Breakdown Display

Show the calculation transparently:

```
+--------------------------------------------------+
|                                                  |
|                                                  |
|            YOUR INVISIBLE COST                   |
|                                                  |
|              $2,400,000                          |
|                per year                          |
|                                                  |
|  +------------------------------------------+    |
|  |                                          |    |
|  |   40,000 hours → $480K direct labor      |    |
|  |              → $720K overhead/loaded     |    |
|  |              → $1.2M invisible costs     |    |
|  |                                          |    |
|  +------------------------------------------+    |
|                                                  |
|     Based on Hackett Group / APQC benchmarks     |
|                                                  |
|                                                  |
|              [ Tap to continue ]                 |
|                                                  |
+--------------------------------------------------+
```

### 5.4 Automation Anywhere Value Proposition Screen (SOURCED)

Visual treatment showing **published, sourced benchmarks only**:

```
+--------------------------------------------------+
|                                                  |
|           AUTOMATION ANYWHERE                    |
|                                                  |
|  +------------------------------------------+    |
|  |                                          |    |
|  |         262% ROI                         |    |
|  |         over 3 years                     |    |
|  |                                          |    |
|  |    Payback in under 12 months            |    |
|  |                                          |    |
|  |    Source: Forrester TEI Study           |    |
|  |                                          |    |
|  +------------------------------------------+    |
|                                                  |
|  +------------------------------------------+    |
|  | DEPARTMENT-SPECIFIC IMPACT               |    |
|  |                                          |    |
|  | [P2P] 78-81% cost reduction              |    |
|  |       82% faster processing              |    |
|  |       Source: Ardent Partners 2024       |    |
|  |                                          |    |
|  | [ITSM] 60% ticket volume reduction       |    |
|  |        37-52% faster resolution          |    |
|  |        Source: ServiceNow Research       |    |
|  |                                          |    |
|  +------------------------------------------+    |
|                                                  |
|  +------------------------------------------+    |
|  |  YOUR POTENTIAL SAVINGS                  |    |
|  |                                          |    |
|  |  Based on 78% cost reduction:            |    |
|  |  Annual Savings: $1,872,000              |    |
|  |  Hours Reclaimed: 31,200                 |    |
|  |                                          |    |
|  +------------------------------------------+    |
|                                                  |
+--------------------------------------------------+
```

### 5.5 Comparison Carousel Updates

Dynamic cards based on calculated values:

```
+--------------------------------------------------+
|                                                  |
|        That's equivalent to...                   |
|                                                  |
|  +------------------------------------------+    |
|  |                                          |    |
|  |              12 FTEs                      |    |
|  |                                          |    |
|  |   full-time employees doing nothing      |    |
|  |   but processing invoices all year       |    |
|  |                                          |    |
|  +------------------------------------------+    |
|                                                  |
|              ● ○ ○                               |
|                                                  |
+--------------------------------------------------+
```

---

## 6. Code Architecture Changes

### 6.1 Files to Create

| File | Purpose |
|------|---------|
| `Models/Department.swift` | New department enum and theme |
| `Models/BenchmarkData.swift` | Industry benchmark constants |
| `Models/CostCalculator.swift` | Cost calculation engine |
| `Models/SavingsCalculator.swift` | AA savings projections |
| `Models/UserInputData.swift` | User input model |
| `Views/SubViews/DepartmentSelectionView.swift` | New department selector |
| `Views/SubViews/DepartmentInputView.swift` | Department-specific inputs |
| `Views/SubViews/CostBreakdownView.swift` | Visual cost breakdown |
| `Views/SubViews/AAValuePropositionView.swift` | 6/9 month savings display |

### 6.2 Files to Modify

| File | Changes |
|------|---------|
| `Models/ExperienceViewModel.swift` | Replace `Industry` with `Department`, add cost calculation integration, new phase for AA value prop |
| `Views/NarrativeView.swift` | Update phase routing, add new views, update narration keys |
| `Models/AudioManager.swift` | New narration keys, update scripts, add modular number support |
| `Views/SubViews/Animations.swift` | Add new animation views for cost breakdown, savings timeline |

### 6.3 Files to Remove/Deprecate

| File | Action |
|------|--------|
| `IndustryContent` struct | Replace with `DepartmentContent` |
| Industry-specific narrations | Replace with department narrations |

### 6.4 Phase Enum Update

```swift
enum Tier1Phase: Int, CaseIterable {
    case waiting = 0
    case emotionalIntro          // Keep - emotional grounding
    case departmentSelection     // RENAMED from industrySelection
    case departmentInput         // NEW - department-specific input
    case personalInput           // Simplify - just rate/overhead
    case buildingTension         // Keep - department-aware
    case departmentVignette      // RENAMED from industryVignette
    case patternBreak            // Keep
    case suckerPunchReveal       // Keep - now shows calculated cost
    case costBreakdown           // NEW - hours → direct → indirect → invisible
    case comparisonCarousel      // Keep - dynamic values
    case aaValueProposition      // NEW - 6mo/9mo specific claims
    case agenticOrchestration    // Keep
    case automationAnywhereReveal // Keep
    case humanReturn             // Keep
    case callToAction            // Keep
    case complete
}
```

---

## 7. Implementation Phases

### Phase 1: Data Model Foundation (2-3 days)

1. Create `Department.swift` with new enum
2. Create `BenchmarkData.swift` with all benchmark constants
3. Create `UserInputData.swift` with department-specific input structures
4. Create `CostCalculator.swift` with calculation logic
5. Create `SavingsCalculator.swift` with AA projection logic
6. Write unit tests for calculations

### Phase 2: ViewModel Updates (1-2 days)

1. Update `ExperienceViewModel.swift`:
   - Replace `selectedIndustry` with `selectedDepartment`
   - Add `userInputData` property
   - Add `calculatedCost` computed property
   - Add `savingsProjection` computed property
   - Update phase enum and transitions
   - Add new phase handling

### Phase 3: UI Components (3-4 days)

1. Create `DepartmentSelectionView.swift`
2. Create `DepartmentInputView.swift` (with P2P, O2C, CS, ITSM variants)
3. Create `CostBreakdownView.swift`
4. Create `AAValuePropositionView.swift`
5. Update `PersonalizationInputView` for simplified rate input
6. Update comparison carousel for dynamic values

### Phase 4: Narration & Audio (2-3 days)

1. Update `AudioManager.swift`:
   - Add new narration keys
   - Update script dictionary
   - Add support for dynamic number insertion (if using TTS)
2. Record new audio files (or configure TTS)
3. Update narration timing in view model

### Phase 5: Integration & Polish (2-3 days)

1. Update `NarrativeView.swift` with new phase routing
2. Connect all views with view model
3. Animation refinements
4. Accessibility updates
5. Testing on device

### Phase 6: Audio Production (External)

1. Record new narration scripts
2. Process and optimize audio files
3. Integrate into app bundle

---

## 8. File-by-File Changes

### 8.1 ExperienceViewModel.swift

```diff
- enum Industry: String, CaseIterable, Identifiable {
-     case finance = "finance"
-     case supplyChain = "supply"
-     case healthcare = "health"
+ // MOVED to Models/Department.swift
+ import Department

  @Observable
  class ExperienceViewModel {
      // Core State
      var currentPhase: Tier1Phase = .waiting
      var isExperienceActive: Bool = false

-     // Industry Selection
-     var selectedIndustry: Industry?
+     // Department Selection
+     var selectedDepartment: Department?
+
+     // User Input
+     var userInput = UserInputData()
+
+     // Calculated Values
+     var costBreakdown: CostBreakdown? {
+         guard selectedDepartment != nil else { return nil }
+         return CostCalculator(userInput: userInput).calculateInvisibleCost()
+     }
+
+     var savingsProjection: (sixMonth: SavingsProjection, nineMonth: SavingsProjection)? {
+         guard let cost = costBreakdown else { return nil }
+         let calculator = SavingsCalculator(currentCost: cost)
+         return (calculator.sixMonthSavings, calculator.nineMonthSavings)
+     }

-     // Sucker Punch Data
-     var suckerPunchData: SuckerPunchData? {
-         guard let industry = selectedIndustry else { return nil }
-         return IndustryContent.suckerPunchData(for: industry)
-     }
+     // Sucker Punch uses calculated cost
+     var suckerPunchAmount: Double {
+         costBreakdown?.totalCost ?? 0
+     }

      // ... rest of implementation
  }
```

### 8.2 NarrativeView.swift

```diff
  @ViewBuilder
  private var phaseContent: some View {
      switch viewModel.currentPhase {
-     case .industrySelection:
-         IndustrySelectionView(
-             selectedIndustry: $viewModel.selectedIndustry,
-             onSelection: { industry in
-                 viewModel.selectIndustry(industry)
+     case .departmentSelection:
+         DepartmentSelectionView(
+             selectedDepartment: $viewModel.selectedDepartment,
+             onSelection: { department in
+                 viewModel.selectDepartment(department)
              },
              narrationFinished: narrationFinished
          )
+
+     case .departmentInput:
+         DepartmentInputView(
+             department: viewModel.selectedDepartment!,
+             userInput: $viewModel.userInput,
+             onContinue: {
+                 viewModel.advanceToNextPhase()
+             }
+         )

      // ... other cases updated similarly

+     case .costBreakdown:
+         CostBreakdownView(
+             costBreakdown: viewModel.costBreakdown!,
+             onContinue: {
+                 viewModel.advanceToNextPhase()
+             }
+         )
+
+     case .aaValueProposition:
+         AAValuePropositionView(
+             savings: viewModel.savingsProjection!,
+             onContinue: {
+                 viewModel.advanceToNextPhase()
+             }
+         )
      }
  }
```

### 8.3 AudioManager.swift - New Narration Keys

```swift
private let narratorLines: [String: String] = [
    // Opening (unchanged)
    "opening_1": "Every organization... carries a hidden cost.",
    "opening_2": "Most leaders... never see it.",

    // Department Selection
    "choose_department": "Choose your department to begin.",

    // Department Input
    "department_input": "Let's calculate your hidden cost. Tell us about your organization.",

    // Building Tension - P2P
    "building_p2p": "Let's take one process... invoice reconciliation. Every invoice requires matching... verification... approval. Industry data shows the hidden hours add up fast.",

    // Building Tension - O2C
    "building_o2c": "Let's examine your order-to-cash cycle. From order to invoice to payment... every step has friction. Working capital tied up... waiting.",

    // Building Tension - Customer Support
    "building_cs": "Consider your support operation. Tickets flowing in... agents stretched thin. Countless hours on questions that could answer themselves.",

    // Building Tension - ITSM
    "building_itsm": "Look at your IT service desk. Password resets... basic troubleshooting... the same questions over and over. A cycle of repetitive resolution.",

    // Vignettes
    "vignette_p2p": "Hours... lost... to matching invoices machines were built to handle.",
    "vignette_o2c": "Cash flow... delayed... by processes that should be instant.",
    "vignette_cs": "Agents... drowning... in tickets AI could resolve in seconds.",
    "vignette_itsm": "Engineers... reduced... to password reset specialists.",

    // Pattern Break
    "pattern_break": "But what if... you could see the real number?",

    // Sucker Punch (general - numbers shown visually)
    "sucker_punch_reveal": "Direct costs. Indirect costs. And the invisible cost you never see on a spreadsheet. This is real money. Your money. Every single year.",

    // Cost Breakdown
    "cost_breakdown": "Hours translate to direct costs. Direct costs carry overhead. And overhead hides... the invisible cost. Based on Hackett and APQC benchmarks.",

    // AA Value Proposition (SOURCED - Choose based on department)
    // P2P: Ardent Partners 2024
    "aa_value_p2p": "From twelve dollars an invoice... to two. Seventy-eight percent lower costs. Eighty-two percent faster. Ardent Partners twenty twenty-four.",

    // O2C: APQC/Hackett
    "aa_value_o2c": "Collections accelerated by over a week. Up to seven million in benefits. Hackett Group research.",

    // Customer Support: Gartner
    "aa_value_support": "Eighty billion dollars in service costs... cut by twenty twenty-six. Gartner's projection.",

    // ITSM: ServiceNow
    "aa_value_itsm": "Ticket volume reduced by sixty percent. Resolution fifty-two percent faster. ServiceNow research.",

    // General: Forrester TEI (AA-specific)
    "aa_reveal_forrester": "Two hundred sixty-two percent ROI. Payback in under twelve months. Forrester Total Economic Impact study.",

    // Comparisons (templates - values inserted dynamically or shown visually)
    "comparison_intro": "Let's put that in perspective...",

    // Human Return
    "restoration": "The chains dissolve... one by one.",
    "breathe": "Breathe... this is what's possible.",
    "purpose": "Strategy... not spreadsheets. Innovation... not administration. Leading... not chasing.",

    // Final CTA
    "final_cta": "The invisible cost... ends now. The choice is yours. Where will you lead?"
]
```

---

## 9. Audio Asset Requirements

### 9.1 New Audio Files Needed

| Key | Script | Duration (est.) |
|-----|--------|-----------------|
| `narration_choose_department.mp3` | "Four processes. Four invisible costs..." | 4-5s |
| `narration_department_input.mp3` | "Now... let's get specific..." | 4s |
| `narration_building_p2p.mp3` | "Let's take one process... invoice reconciliation..." | 8-10s |
| `narration_building_o2c.mp3` | "Consider your order-to-cash cycle..." | 8-10s |
| `narration_building_cs.mp3` | "Look at your support operation..." | 8-10s |
| `narration_building_itsm.mp3` | "Your IT service desk..." | 8-10s |
| `narration_vignette_p2p.mp3` | "Hours... lost... to matching invoices..." | 3s |
| `narration_vignette_o2c.mp3` | "Cash flow... delayed..." | 3s |
| `narration_vignette_cs.mp3` | "Agents... drowning..." | 3s |
| `narration_vignette_itsm.mp3` | "Engineers... reduced..." | 3s |
| `narration_sucker_punch_reveal.mp3` | "Direct costs. Indirect costs..." | 6-7s |
| `narration_cost_breakdown.mp3` | "Hours translate to direct costs..." | 6s |
| `narration_aa_value_p2p.mp3` | "From twelve dollars an invoice... to two. 78% lower. Ardent Partners." | 6s |
| `narration_aa_value_o2c.mp3` | "Collections accelerated by over a week. Up to $7M. Hackett Group." | 5s |
| `narration_aa_value_support.mp3` | "$80B in service costs cut by 2026. Gartner." | 4s |
| `narration_aa_value_itsm.mp3` | "Ticket volume reduced 60%. 52% faster. ServiceNow." | 5s |
| `narration_aa_reveal_forrester.mp3` | "262% ROI. Payback under 12 months. Forrester TEI." | 5s |
| `narration_comparison_intro.mp3` | "Let's put that in perspective..." | 2s |

### 9.2 Audio Files to Remove/Replace

| Current File | Action |
|--------------|--------|
| `narration_building_finance.mp3` | Remove |
| `narration_building_supply.mp3` | Remove |
| `narration_building_health.mp3` | Remove |
| `narration_vignette_finance_enhanced.mp3` | Remove |
| `narration_vignette_supply_enhanced.mp3` | Remove |
| `narration_vignette_health_enhanced.mp3` | Remove |
| `narration_sucker_punch_finance.mp3` | Remove |
| `narration_sucker_punch_supply.mp3` | Remove |
| `narration_sucker_punch_health.mp3` | Remove |
| `narration_comparison_finance_*.mp3` | Remove |
| `narration_comparison_supply_*.mp3` | Remove |
| `narration_comparison_health_*.mp3` | Remove |

---

## Appendix A: Sample P2P Flow Walkthrough

### User Journey

1. **Emotional Intro**
   - "Every organization carries a hidden cost. Most leaders never see it."
   - Floating windows overwhelm, tension builds

2. **Department Selection**
   - User sees 4 cards: P2P, O2C, Customer Support, ITSM
   - Narration: "Choose your department to begin."
   - User taps **P2P**

3. **Department Input**
   - Screen shows P2P-specific inputs:
     - Invoices per month: [User selects 5,000]
     - AP Team Size: [User enters 10 FTEs]
     - Current Automation: [User selects Manual]
   - Average hourly rate: [User selects $100]
   - Live preview shows: "Estimated: $2.4M/year" (visual only)
   - Narration: "Let's calculate your hidden cost. Tell us about your organization."

4. **Building Tension**
   - Background intensifies
   - Narration: "Let's take one process... invoice reconciliation. Every invoice requires matching... verification... approval. Industry data shows the hidden hours add up fast."
   - Specific numbers (40,000 hours, etc.) appear visually on screen - not in narration

5. **Industry Vignette**
   - Icon pulses, metrics fade in
   - Narration: "Hours... lost... to matching invoices machines were built to handle."
   - Metrics shown: 40,000 hours, 60,000 invoices, $20 per invoice

6. **Pattern Break**
   - White flash
   - Narration: "But what if... you could see the real number?"
   - "Tap to reveal"

7. **Sucker Punch Reveal**
   - Giant number counts up: **$2,400,000**
   - Narration: "Direct costs. Indirect costs. And the invisible cost..."
   - Tap to continue

8. **Cost Breakdown** (NEW)
   - Animated flow: Hours → Direct → Indirect → Invisible
   - Narration: "Hours translate to direct costs..."
   - Shows: 40,000 hrs → $480K direct → $720K indirect → $1.2M invisible
   - Source citation: "Based on Hackett/APQC benchmarks"

9. **Comparison Carousel**
   - Card 1: "That's 12 FTEs doing nothing but processing invoices"
   - Card 2: "3 years of your IT budget"
   - Card 3: "150 strategic projects that never happened"

10. **AA Value Proposition** (NEW - SOURCED)
    - Shows Forrester TEI ROI data and department-specific benchmarks
    - Narration: "Two hundred sixty-two percent ROI. Payback in under twelve months. These aren't promises... they're published results."
    - Visual:
      ```
      262% ROI (Forrester TEI)
      78-81% cost reduction (Ardent Partners 2024)
      Your Potential Savings: $1.87M/year
      ```

11. **Agentic Orchestration**
    - Visualization of AI agents working
    - Narration: "Imagine intelligence that doesn't just respond... but orchestrates."

12. **AA Brand Reveal**
    - Logo animation
    - Narration: "Automation Anywhere... elevating human potential."

13. **Human Return**
    - Workers restored to meaningful work
    - Narration: "Strategy... not spreadsheets. Innovation... not administration."

14. **Call to Action**
    - Final screen with "RESTART" and "DEMO" buttons
    - Narration: "The invisible cost ends now. The choice is yours."

---

## Appendix B: Quick Reference - SOURCED Benchmark Numbers

### P2P Cost Per Invoice (SOURCED)
| Performance | Cost | Source |
|-------------|------|--------|
| Top Performers | $4.98 | APQC |
| Median | $7.75 | APQC |
| Bottom | $12.44 | APQC |
| Best-in-Class | $2.78 | Ardent Partners 2024 |
| Automated | $2.02 | Stampli |

**Key Insights (SOURCED):**
- 78-81% cost reduction with automation (Ardent Partners 2024)
- 82% faster processing (Ardent Partners 2024)
- 3.1 days vs 17.4 days cycle time (Ardent Partners 2024)

### O2C Metrics (SOURCED)
| Metric | Value | Source |
|--------|-------|--------|
| DSO Median | 38 days | APQC |
| DSO Top Performers | <30 days | APQC |
| AI DSO Reduction | 8.4 days | Hackett Group |
| Cost Reduction | 79% | Auxis |

### Customer Support (SOURCED)
| Metric | Value | Source |
|--------|-------|--------|
| Cost per Ticket (NA Avg) | $22 | HDI/ServiceNow |
| Cost Range | $6-$40 | HDI |
| AI Cost Savings by 2026 | $80B | Gartner |
| Chatbot Savings | 30-50% | Industry |

### ITSM (SOURCED)
| Metric | Value | Source |
|--------|-------|--------|
| Tier-1 Ticket Cost | $22 | MetricNet |
| Tier-3 Ticket Cost | $104 | MetricNet |
| AI Ticket Volume Reduction | 60% | ServiceNow |
| Handling Speed Improvement | 37-52% | ServiceNow |

### Automation Anywhere ROI (Forrester TEI)
| Metric | Value |
|--------|-------|
| 3-Year ROI | **262%** |
| Payback Period | **<12 months** |
| Total 3-Year Benefits | **$13.2M** |

### Full Citation List
| # | Publisher | URL |
|---|-----------|-----|
| 1 | APQC | https://transformious.com/accounts-payable/5-steps-to-lowering-the-cost-of-ap-processing-and-reducing-transaction-processing-time/ |
| 2 | Ardent Partners 2024 | https://www.bottomline.com/resources/blog/ardent-2024-epayables-study-automation-ai-earning-ap-a-seat-at-the-strategy-table |
| 3 | Stampli | https://www.stampli.com/blog/accounts-payable/procure-to-pay-kpis/ |
| 4 | Forrester/Basware | https://tei.forrester.com/go/basware/apautomation/ |
| 5 | Auxis | https://www.auxis.com/accounts-receivable-automation-benefits-and-best-practices/ |
| 6 | MetricNet | https://www.ghdsi.com/blog/evaluate-reduce-it-service-desk-cost-per-ticket/ |
| 7 | ServiceNow | https://www.servicenow.com/products/itsm/help-desk-statistics.html |
| 8 | HDI | https://www.thinkhdi.com/library/supportworld/2025/5-insights-hdi-state-of-tech-support-2025 |
| 9 | Plivo | https://www.plivo.com/blog/contact-center-statistics-benchmarks-2025/ |
| 10 | Pylon | https://www.usepylon.com/blog/ai-powered-customer-support-guide |
| 11 | Netfor | https://www.netfor.com/2025/04/02/it-help-desk-support-2/ |
| 12 | Forrester TEI (AA) | https://www.automationanywhere.com/company/blog/company-news/forrester-study-huge-rpa-return-in-short-time-frame |
| 13 | Hackett Group | https://www.auxis.com/accounts-receivable-automation-benefits-and-best-practices/ |

---

## Appendix C: Narration Script - Full P2P Version

For voice-over recording, here's the complete P2P narration script with timing notes:

```
[0:00] OPENING
"Every organization... [pause] carries a hidden cost."
"Most leaders... [pause] never see it."

[0:08] DEPARTMENT SELECTION
"Choose your department to begin."

[0:12] PERSONAL INPUT
"Let's calculate your hidden cost. [pause] Tell us about your organization."

[0:20] BUILDING TENSION - P2P
"Let's take one process... [pause] invoice reconciliation. [pause]
Every invoice requires matching... [pause] verification... [pause] approval. [pause]
Industry data shows the hidden hours add up fast."

[0:40] VIGNETTE
"Hours... [pause] lost... [pause] to matching invoices [pause] machines were built to handle."

[0:47] PATTERN BREAK
"But what if... [pause] you could see the real number?"

[0:52] SUCKER PUNCH
"Direct costs. [pause] Indirect costs. [pause] And the invisible cost [pause] you never see on a spreadsheet. [pause]
This is real money. [pause] Your money. [pause] Every single year."

[1:05] COST BREAKDOWN
"Hours translate to direct costs. [pause]
Direct costs carry overhead. [pause]
And overhead hides... [pause] the invisible cost. [pause]
Based on Hackett and APQC benchmarks."

[1:18] COMPARISONS
"Let's put that in perspective..."

[1:25] AA VALUE PROPOSITION (SOURCED - P2P VERSION)
"From twelve dollars an invoice... [pause] to two. [pause]
Seventy-eight percent lower costs. [pause] Eighty-two percent faster. [pause]
Based on Ardent Partners' twenty twenty-four ePayables study."

[Source: Ardent Partners 2024 - https://www.bottomline.com/resources/blog/ardent-2024-epayables-study-automation-ai-earning-ap-a-seat-at-the-strategy-table]

[1:42] AGENTIC ORCHESTRATION
"Imagine intelligence... [pause] that doesn't just respond... [pause] but orchestrates. [pause]
Agents that see the whole picture... [pause] that deliver... [pause] before you ask."

[1:55] AA REVEAL
"Automation Anywhere... [pause] elevating human potential."

[2:00] HUMAN RETURN
"The chains dissolve... [pause] one by one."
"Breathe... [pause] this is what's possible."
"Strategy... not spreadsheets. [pause] Innovation... not administration. [pause] Leading... not chasing."

[2:18] FINAL CTA
"The invisible cost... [pause] ends now. [pause] The choice is yours. [pause] Where will you lead?"

[TOTAL: ~2:25]
```

---

**Document End**

*This plan provides a comprehensive roadmap for transforming the Invisible Cost iPad experience from an emotional, generic storytelling approach to a data-driven, personalized cost calculator with specific, credible benchmarks and clear Automation Anywhere value propositions.*

import Foundation

// MARK: - Cost Calculator
/// Calculates process costs (including hidden/invisible components) using Tarani-approved simplified formulas for Davos 2026
/// Total cost breakdown: Direct Labor (60%) + Overhead (25%) + Invisible (15% - exceptions, rework, opportunity cost)
/// Formulas: Simple multiplication based on transaction costs and volumes
/// Sources: Hackett, APQC, Gartner-type benchmarks (directionally consistent)

struct CostCalculator {

    let userInput: UserInputData

    // MARK: - Tarani-Approved Cost Constants (Davos 2026)

    /// P2P: $25 per transaction → $1 with automation = $24 savings
    /// 6-15 transactions per employee per year (use 15)
    private static let p2pSavingsPerTransaction: Double = 24.0
    private static let p2pTransactionsPerEmployee: Double = 15.0

    /// O2C: $20 per transaction → $1.50 with automation = $18.50 savings
    /// 7-15 transactions per employee per year (use 15)
    private static let o2cSavingsPerTransaction: Double = 18.50
    private static let o2cTransactionsPerEmployee: Double = 15.0

    /// Customer Support: $15 per triage → $0.50 with automation = $14.50 savings
    /// 6-10 transactions per employee served (use 10)
    private static let supportSavingsPerTransaction: Double = 14.50
    private static let supportTransactionsPerEmployee: Double = 10.0

    /// ITSM/Helpdesk: $40 per ticket → $2 with automation = $38 savings
    /// 10-15 tickets per employee supported (use 15)
    private static let itsmSavingsPerTicket: Double = 38.0
    private static let itsmTicketsPerEmployee: Double = 15.0

    // MARK: - Main Calculation

    /// Calculate the total process cost breakdown based on selected department and user inputs
    /// Returns: Direct labor (60%), Overhead (25%), and truly invisible costs (15%)
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
    /// Formula: $24 savings × employees × 15 transactions/employee
    /// Example: 1,000 employees → $24 × 1,000 × 15 = $360,000

    private func calculateP2PCost() -> CostBreakdown {
        let employees = Double(userInput.employeeCount)

        // Tarani's simplified formula
        let totalCost = Self.p2pSavingsPerTransaction * employees * Self.p2pTransactionsPerEmployee

        // Estimate transactions for display
        let annualTransactions = Int(employees * Self.p2pTransactionsPerEmployee)

        // Estimate hours (rough: 15 min per transaction)
        let annualHours = Double(annualTransactions) * 0.25

        return CostBreakdown(
            annualHours: annualHours,
            directCost: totalCost * 0.6,      // 60% direct labor
            indirectCost: totalCost * 0.25,   // 25% overhead
            invisibleCost: totalCost * 0.15,  // 15% hidden costs
            totalCost: totalCost,
            department: .p2p,
            benchmarkSource: "Hackett, APQC, Gartner",
            keyMetrics: [
                KeyMetric(label: "Employees", value: userInput.employeeCount.formattedWithCommas),
                KeyMetric(label: "Transactions/Year", value: annualTransactions.formattedWithCommas),
                KeyMetric(label: "Cost/Transaction", value: "$25 → $1"),
                KeyMetric(label: "Savings/Transaction", value: Self.p2pSavingsPerTransaction.formattedAsCurrency)
            ]
        )
    }

    // MARK: - O2C Calculation
    /// Formula: $18.50 savings × employees × 15 transactions/employee
    /// Example: 1,000 employees → $18.50 × 1,000 × 15 = $277,500

    private func calculateO2CCost() -> CostBreakdown {
        let employees = Double(userInput.employeeCount)

        // Tarani's simplified formula
        let totalCost = Self.o2cSavingsPerTransaction * employees * Self.o2cTransactionsPerEmployee

        // Estimate transactions for display
        let annualTransactions = Int(employees * Self.o2cTransactionsPerEmployee)

        // Estimate hours (rough: 20 min per transaction)
        let annualHours = Double(annualTransactions) * 0.33

        return CostBreakdown(
            annualHours: annualHours,
            directCost: totalCost * 0.6,
            indirectCost: totalCost * 0.25,
            invisibleCost: totalCost * 0.15,
            totalCost: totalCost,
            department: .o2c,
            benchmarkSource: "Hackett, APQC, Gartner",
            keyMetrics: [
                KeyMetric(label: "Employees", value: userInput.employeeCount.formattedWithCommas),
                KeyMetric(label: "Transactions/Year", value: annualTransactions.formattedWithCommas),
                KeyMetric(label: "Cost/Transaction", value: "$20 → $1.50"),
                KeyMetric(label: "Savings/Transaction", value: Self.o2cSavingsPerTransaction.formattedAsCurrency)
            ]
        )
    }

    // MARK: - Customer Support Calculation
    /// Formula: $14.50 savings × customers × avg_org_size × 10 transactions/employee
    /// Example: 100 customers × 500 employees × 10 = $14.50 × 500,000 = $7,250,000

    private func calculateSupportCost() -> CostBreakdown {
        let totalEmployees = Double(userInput.totalCustomerEmployees)

        // Tarani's simplified formula
        let totalCost = Self.supportSavingsPerTransaction * totalEmployees * Self.supportTransactionsPerEmployee

        // Estimate transactions for display
        let annualTransactions = Int(totalEmployees * Self.supportTransactionsPerEmployee)

        // Estimate hours (rough: 10 min per triage)
        let annualHours = Double(annualTransactions) * 0.17

        return CostBreakdown(
            annualHours: annualHours,
            directCost: totalCost * 0.6,
            indirectCost: totalCost * 0.25,
            invisibleCost: totalCost * 0.15,
            totalCost: totalCost,
            department: .customerSupport,
            benchmarkSource: "HDI, ServiceNow, Gartner",
            keyMetrics: [
                KeyMetric(label: "Customers Served", value: userInput.customersServed.formattedWithCommas),
                KeyMetric(label: "Avg Customer Size", value: userInput.avgCustomerOrgSize.formattedWithCommas),
                KeyMetric(label: "Total Employees", value: userInput.totalCustomerEmployees.formattedWithCommas),
                KeyMetric(label: "Savings/Triage", value: Self.supportSavingsPerTransaction.formattedAsCurrency)
            ]
        )
    }

    // MARK: - ITSM Calculation
    /// Formula: $38 savings × customers × avg_org_size × 15 tickets/employee
    /// Example: 100 customers × 500 employees × 15 = $38 × 750,000 = $28,500,000

    private func calculateITSMCost() -> CostBreakdown {
        let totalEmployees = Double(userInput.totalCustomerEmployees)

        // Tarani's simplified formula
        let totalCost = Self.itsmSavingsPerTicket * totalEmployees * Self.itsmTicketsPerEmployee

        // Estimate tickets for display
        let annualTickets = Int(totalEmployees * Self.itsmTicketsPerEmployee)

        // Estimate hours (rough: 30 min per ticket)
        let annualHours = Double(annualTickets) * 0.5

        return CostBreakdown(
            annualHours: annualHours,
            directCost: totalCost * 0.6,
            indirectCost: totalCost * 0.25,
            invisibleCost: totalCost * 0.15,
            totalCost: totalCost,
            department: .itsm,
            benchmarkSource: "MetricNet, ServiceNow",
            keyMetrics: [
                KeyMetric(label: "Customers Served", value: userInput.customersServed.formattedWithCommas),
                KeyMetric(label: "Avg Customer Size", value: userInput.avgCustomerOrgSize.formattedWithCommas),
                KeyMetric(label: "Total Supported", value: userInput.totalCustomerEmployees.formattedWithCommas),
                KeyMetric(label: "Savings/Ticket", value: Self.itsmSavingsPerTicket.formattedAsCurrency)
            ]
        )
    }
}

// MARK: - Cost Breakdown Result
// Note: CostBreakdown struct is defined in Department.swift to avoid circular dependencies
// This extension adds computed properties for display formatting

extension CostBreakdown {

    /// Formatted total cost for display
    var formattedTotalCost: String {
        totalCost.formattedAsCurrency
    }

    /// Formatted direct cost for display
    var formattedDirectCost: String {
        directCost.formattedAsCurrency
    }

    /// Formatted indirect cost for display
    var formattedIndirectCost: String {
        indirectCost.formattedAsCurrency
    }

    /// Formatted invisible cost for display
    var formattedInvisibleCost: String {
        invisibleCost.formattedAsCurrency
    }

    /// Formatted hours for display
    var formattedHours: String {
        Int(annualHours).formattedWithCommas
    }

    /// Spoken format of total cost for TTS
    var spokenTotalCost: String {
        totalCost.formattedSpoken + " dollars"
    }

    /// Percentage breakdown for visualization
    var percentageBreakdown: (direct: Double, indirect: Double, invisible: Double) {
        guard totalCost > 0 else { return (0, 0, 0) }
        let total = directCost + indirectCost + invisibleCost
        return (
            direct: directCost / total,
            indirect: indirectCost / total,
            invisible: invisibleCost / total
        )
    }

    /// Summary text for the cost breakdown
    var summaryText: String {
        """
        \(formattedHours) hours of processing time
        \(formattedDirectCost) in direct labor costs
        \(formattedIndirectCost) in overhead and loaded costs
        \(formattedInvisibleCost) in invisible costs (exceptions, rework, opportunity)
        """
    }
}

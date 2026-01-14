import Foundation

// MARK: - Cost Calculator
/// Calculates invisible costs based on user input and sourced benchmarks
/// All calculations use published industry data from APQC, Ardent Partners, HDI, MetricNet, etc.

struct CostCalculator {

    let userInput: UserInputData

    // MARK: - Main Calculation

    /// Calculate the invisible cost based on selected department and user inputs
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
    /// Based on Ardent Partners 2024, APQC, Stampli benchmarks

    private func calculateP2PCost() -> CostBreakdown {
        let input = userInput.p2pData
        let annualInvoices = input.invoicesPerMonth * 12

        // Get cost per invoice for current automation level
        let costRange = BenchmarkData.P2P.CostPerInvoice.cost(for: input.currentAutomationLevel)
        let avgCostPerInvoice = (costRange.lowerBound + costRange.upperBound) / 2

        // Calculate hours based on automation level
        let hoursPerThousand = BenchmarkData.P2P.hoursPerThousandInvoices(for: input.currentAutomationLevel)
        let annualHours = (Double(annualInvoices) / 1000.0) * hoursPerThousand

        // Direct labor cost
        let directCost = annualHours * userInput.averageHourlyRate

        // Exception handling costs (exceptions cost ~2x to resolve)
        let exceptionRate = BenchmarkData.P2P.ExceptionRate.rate(for: input.currentAutomationLevel)
        let totalProcessingCost = Double(annualInvoices) * avgCostPerInvoice
        let exceptionCost = totalProcessingCost * exceptionRate * 2.0

        // Indirect/overhead cost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)

        // Invisible cost = opportunity cost + exception handling + rework
        let invisibleCost = indirectCost + exceptionCost

        // Total cost
        let totalCost = directCost + indirectCost + invisibleCost

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: totalCost,
            department: .p2p,
            benchmarkSource: BenchmarkData.P2P.source,
            keyMetrics: [
                KeyMetric(label: "Invoices/Year", value: annualInvoices.formattedWithCommas),
                KeyMetric(label: "Processing Hours", value: Int(annualHours).formattedWithCommas),
                KeyMetric(label: "Cost per Invoice", value: avgCostPerInvoice.formattedAsCurrency),
                KeyMetric(label: "Exception Rate", value: "\(Int(exceptionRate * 100))%")
            ]
        )
    }

    // MARK: - O2C Calculation
    /// Based on APQC, Hackett Group, Auxis benchmarks

    private func calculateO2CCost() -> CostBreakdown {
        let input = userInput.o2cData
        let annualOrders = input.ordersPerMonth * 12

        // Infer automation level from DSO
        let automationLevel = input.inferredAutomationLevel

        // Get cost per order
        let costRange = BenchmarkData.O2C.costPerOrder(for: automationLevel)
        let avgCostPerOrder = (costRange.lowerBound + costRange.upperBound) / 2

        // Direct cost of order processing
        let directCost = Double(annualOrders) * avgCostPerOrder

        // Calculate cash flow impact from DSO
        // Assume average order value of $500
        let avgOrderValue = 500.0
        let annualRevenue = Double(annualOrders) * avgOrderValue
        let dailyRevenue = annualRevenue / 365.0
        let cashTiedUp = dailyRevenue * Double(input.currentDSO)

        // Working capital cost (assume 8% cost of capital)
        let workingCapitalCost = cashTiedUp * 0.08

        // Error-related costs
        let errorRate = BenchmarkData.O2C.orderErrorRate(for: automationLevel)
        let errorCostPerError = 50.0 // $50 per error to investigate and fix
        let errorCost = Double(annualOrders) * errorRate * errorCostPerError

        // Calculate hours (70% of FTE time on O2C tasks)
        let annualHours = Double(input.fteCount) * 2080 * 0.7

        // Indirect cost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)

        // Invisible cost
        let invisibleCost = workingCapitalCost + errorCost + indirectCost

        // Total cost
        let totalCost = directCost + invisibleCost

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: totalCost,
            department: .o2c,
            benchmarkSource: BenchmarkData.O2C.source,
            keyMetrics: [
                KeyMetric(label: "Orders/Year", value: annualOrders.formattedWithCommas),
                KeyMetric(label: "Days Sales Outstanding", value: "\(input.currentDSO) days"),
                KeyMetric(label: "Cash Tied Up", value: cashTiedUp.formattedAsCurrency),
                KeyMetric(label: "Working Capital Cost", value: workingCapitalCost.formattedAsCurrency)
            ]
        )
    }

    // MARK: - Customer Support Calculation
    /// FORMULA: Customers Served x Avg Customer Org Size x Cost per Employee
    /// Based on HDI, ServiceNow, Gartner benchmarks

    private func calculateSupportCost() -> CostBreakdown {
        let input = userInput.customerSupportData

        // Core calculation per Neeti's formula
        let totalEmployeesServed = userInput.totalCustomerEmployees
        let costPerEmployee = input.costPerEmployeeServed

        // Base invisible cost from serving customer employees
        let baseCost = Double(totalEmployeesServed) * costPerEmployee

        // Get automation level and channel-based costs
        let automationLevel = input.inferredAutomationLevel
        let costRange = BenchmarkData.CustomerSupport.CostPerTicket.cost(for: input.currentChannel)
        let avgCostPerTicket = (costRange.lowerBound + costRange.upperBound) / 2

        // Estimate tickets based on employee base
        let estimatedAnnualTickets = Double(totalEmployeesServed) * input.ticketsPerEmployeePerYear

        // Calculate handle time and hours
        let avgHandleTime = BenchmarkData.CustomerSupport.avgHandleTime(for: automationLevel)
        let annualHours = (estimatedAnnualTickets * avgHandleTime) / 60.0

        // Direct cost
        let directCost = baseCost

        // Indirect/overhead cost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)

        // FCR impact - repeat contacts cost 1.5x
        let fcr = BenchmarkData.CustomerSupport.firstContactResolution(for: automationLevel)
        let repeatContactCost = estimatedAnnualTickets * (1.0 - fcr) * avgCostPerTicket * 1.5

        // Customer churn impact (conservative estimate)
        let churnImpact = baseCost * 0.05 // 5% of base cost

        // Invisible cost
        let invisibleCost = indirectCost + repeatContactCost + churnImpact

        // Total cost
        let totalCost = directCost + invisibleCost

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: totalCost,
            department: .customerSupport,
            benchmarkSource: BenchmarkData.CustomerSupport.source,
            keyMetrics: [
                KeyMetric(label: "Customers Served", value: userInput.customersServed.formattedWithCommas),
                KeyMetric(label: "Avg Customer Size", value: userInput.avgCustomerOrgSize.formattedWithCommas),
                KeyMetric(label: "Total Employees", value: totalEmployeesServed.formattedWithCommas),
                KeyMetric(label: "Cost/Employee", value: costPerEmployee.formattedAsCurrency)
            ]
        )
    }

    // MARK: - ITSM Calculation
    /// FORMULA: Customers Served x Avg Customer Org Size x Cost per Employee
    /// Based on MetricNet, ServiceNow, Forrester benchmarks

    private func calculateITSMCost() -> CostBreakdown {
        let input = userInput.itsmData

        // Core calculation per Neeti's formula
        let totalEmployeesSupported = userInput.totalCustomerEmployees
        let costPerEmployee = input.costPerEmployeeSupported

        // Base invisible cost from supporting customer employees
        let baseCost = Double(totalEmployeesSupported) * costPerEmployee

        // Estimate incidents based on employee base
        let estimatedAnnualIncidents = Double(totalEmployeesSupported) * input.incidentsPerEmployeePerYear

        // Estimate password resets (roughly 10% of employee base per year)
        let estimatedPasswordResets = Double(totalEmployeesSupported) * 0.10

        // Get automation level
        let automationLevel = input.inferredAutomationLevel(totalEmployees: totalEmployeesSupported)

        // Resolution time and password reset costs
        let mttr = BenchmarkData.ITSM.meanTimeToResolve(for: automationLevel)
        let passwordResetCostPer = BenchmarkData.ITSM.passwordResetCost(for: automationLevel)

        // Password reset total cost (major hidden cost)
        let passwordTotalCost = estimatedPasswordResets * passwordResetCostPer

        // Calculate hours for incident resolution
        let annualHours = estimatedAnnualIncidents * mttr

        // Downtime/productivity loss
        // Average 5 users affected per incident, lose half their hourly rate
        let avgUsersAffected = 5.0
        let productivityLoss = estimatedAnnualIncidents * mttr * avgUsersAffected * (userInput.averageHourlyRate / 2)

        // Escalation costs (20% of incidents escalate to Tier-3)
        let escalationRate = 0.20
        let tier3Premium = BenchmarkData.ITSM.CostPerTicket.tier3Escalated - BenchmarkData.ITSM.CostPerTicket.tier1
        let escalationCost = estimatedAnnualIncidents * escalationRate * tier3Premium

        // Direct cost
        let directCost = baseCost + passwordTotalCost

        // Indirect cost
        let indirectCost = directCost * (userInput.overheadMultiplier - 1.0)

        // Invisible cost
        let invisibleCost = productivityLoss + escalationCost + indirectCost

        // Total cost
        let totalCost = directCost + invisibleCost

        return CostBreakdown(
            annualHours: annualHours,
            directCost: directCost,
            indirectCost: indirectCost,
            invisibleCost: invisibleCost,
            totalCost: totalCost,
            department: .itsm,
            benchmarkSource: BenchmarkData.ITSM.source,
            keyMetrics: [
                KeyMetric(label: "Customers Served", value: userInput.customersServed.formattedWithCommas),
                KeyMetric(label: "Avg Customer Size", value: userInput.avgCustomerOrgSize.formattedWithCommas),
                KeyMetric(label: "Total Supported", value: totalEmployeesSupported.formattedWithCommas),
                KeyMetric(label: "Password Reset Cost", value: passwordTotalCost.formattedAsCurrency)
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

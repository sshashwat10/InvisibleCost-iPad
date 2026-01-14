import Foundation

// MARK: - Savings Calculator
/// Calculates AA savings projections using ONLY sourced data
/// Primary source: Forrester Total Economic Impact Study

struct SavingsCalculator {

    let costBreakdown: CostBreakdown
    let userInput: UserInputData

    // MARK: - Main Savings Projection

    func calculateSavingsProjection() -> SavingsProjection {
        switch userInput.department {
        case .p2p:
            return calculateP2PSavings()
        case .o2c:
            return calculateO2CSavings()
        case .customerSupport:
            return calculateSupportSavings()
        case .itsm:
            return calculateITSMSavings()
        }
    }

    // MARK: - P2P Savings
    /// Sources: Ardent Partners 2024, Forrester/Basware TEI

    private func calculateP2PSavings() -> SavingsProjection {
        // Ardent Partners 2024: 78-81% cost reduction with AP automation
        let costReductionRange = BenchmarkData.P2P.AutomationImpact.costReduction
        let midpointReduction = (costReductionRange.lowerBound + costReductionRange.upperBound) / 2

        let annualSavings = costBreakdown.totalCost * midpointReduction
        let threeYearSavings = annualSavings * 3

        // Ardent Partners 2024: 82% faster processing
        let timeRecoveryPercent = BenchmarkData.P2P.AutomationImpact.speedImprovement
        let hoursRecovered = costBreakdown.annualHours * timeRecoveryPercent

        // Forrester TEI study ROI data
        let roi = BenchmarkData.AutomationAnywhere.roiThreeYear
        let paybackMonths = BenchmarkData.AutomationAnywhere.paybackMonths

        return SavingsProjection(
            annualSavings: annualSavings,
            threeYearSavings: threeYearSavings,
            hoursRecovered: hoursRecovered,
            roi: roi,
            paybackMonths: paybackMonths,
            department: .p2p,
            primaryBenefit: "78-81% cost reduction per invoice",
            primarySource: "Ardent Partners 2024 ePayables Study",
            keyBenefits: [
                BenefitItem(
                    icon: "dollarsign.circle.fill",
                    headline: "\(Int(midpointReduction * 100))%",
                    description: "Cost reduction per invoice",
                    source: "Ardent Partners 2024"
                ),
                BenefitItem(
                    icon: "gauge.with.needle.fill",
                    headline: "\(Int(timeRecoveryPercent * 100))%",
                    description: "Faster processing time",
                    source: "Ardent Partners 2024"
                ),
                BenefitItem(
                    icon: "arrow.down.circle.fill",
                    headline: "\(Int((1.0 - BenchmarkData.P2P.ExceptionRate.bestInClass / BenchmarkData.P2P.ExceptionRate.average) * 100))%",
                    description: "Reduction in exceptions",
                    source: "Forrester/Basware TEI"
                )
            ],
            forresterData: createForresterData()
        )
    }

    // MARK: - O2C Savings
    /// Sources: Hackett Group, APQC, Auxis

    private func calculateO2CSavings() -> SavingsProjection {
        // Auxis: 79% invoice cost reduction, 60% handle time reduction
        let invoiceCostReduction = BenchmarkData.O2C.AutomationImpact.invoiceCostReduction
        let handleTimeReduction = BenchmarkData.O2C.AutomationImpact.handleTimeReduction

        let annualSavings = costBreakdown.totalCost * invoiceCostReduction
        let threeYearSavings = annualSavings * 3

        // APQC/Hackett: 30-50% faster cycle time
        let cycleTimeImprovement = BenchmarkData.O2C.AutomationImpact.cycleTimeImprovement
        let avgCycleImprovement = (cycleTimeImprovement.lowerBound + cycleTimeImprovement.upperBound) / 2
        let hoursRecovered = costBreakdown.annualHours * avgCycleImprovement

        // DSO improvement
        let dsoReduction = BenchmarkData.O2C.DSO.aiReduction

        let roi = BenchmarkData.AutomationAnywhere.roiThreeYear
        let paybackMonths = BenchmarkData.AutomationAnywhere.paybackMonths

        return SavingsProjection(
            annualSavings: annualSavings,
            threeYearSavings: threeYearSavings,
            hoursRecovered: hoursRecovered,
            roi: roi,
            paybackMonths: paybackMonths,
            department: .o2c,
            primaryBenefit: "79% invoice cost reduction, 8.4 days DSO improvement",
            primarySource: "Auxis, Hackett Group",
            keyBenefits: [
                BenefitItem(
                    icon: "dollarsign.circle.fill",
                    headline: "\(Int(invoiceCostReduction * 100))%",
                    description: "Invoice cost reduction",
                    source: "Auxis AR Automation Study"
                ),
                BenefitItem(
                    icon: "calendar.badge.minus",
                    headline: "\(dsoReduction)",
                    description: "Days reduction in DSO",
                    source: "Hackett Group"
                ),
                BenefitItem(
                    icon: "clock.arrow.circlepath",
                    headline: "\(Int(handleTimeReduction * 100))%",
                    description: "Handle time reduction",
                    source: "Auxis AR Automation Study"
                )
            ],
            forresterData: createForresterData()
        )
    }

    // MARK: - Customer Support Savings
    /// Sources: Gartner, HDI, Pylon

    private func calculateSupportSavings() -> SavingsProjection {
        // Gartner: 30-50% chatbot cost savings
        let chatbotSavings = BenchmarkData.CustomerSupport.AutomationImpact.chatbotCostSavings
        let avgChatbotSavings = (chatbotSavings.lowerBound + chatbotSavings.upperBound) / 2

        let annualSavings = costBreakdown.totalCost * avgChatbotSavings
        let threeYearSavings = annualSavings * 3

        // Pylon: 50-60% faster response
        let responseImprovement = BenchmarkData.CustomerSupport.AutomationImpact.responseSpeedImprovement
        let avgResponseImprovement = (responseImprovement.lowerBound + responseImprovement.upperBound) / 2
        let hoursRecovered = costBreakdown.annualHours * avgResponseImprovement

        let roi = BenchmarkData.AutomationAnywhere.roiThreeYear
        let paybackMonths = BenchmarkData.AutomationAnywhere.paybackMonths

        return SavingsProjection(
            annualSavings: annualSavings,
            threeYearSavings: threeYearSavings,
            hoursRecovered: hoursRecovered,
            roi: roi,
            paybackMonths: paybackMonths,
            department: .customerSupport,
            primaryBenefit: "30-50% cost reduction via AI assistance",
            primarySource: "Gartner, HDI, Pylon",
            keyBenefits: [
                BenefitItem(
                    icon: "dollarsign.circle.fill",
                    headline: "\(Int(avgChatbotSavings * 100))%",
                    description: "Cost reduction via AI",
                    source: "Gartner"
                ),
                BenefitItem(
                    icon: "gauge.with.needle.fill",
                    headline: "\(Int(avgResponseImprovement * 100))%",
                    description: "Faster response time",
                    source: "Pylon AI Support Guide"
                ),
                BenefitItem(
                    icon: "person.fill.checkmark",
                    headline: "+20%",
                    description: "First contact resolution improvement",
                    source: "HDI Benchmarks"
                )
            ],
            forresterData: createForresterData()
        )
    }

    // MARK: - ITSM Savings
    /// Sources: ServiceNow, Forrester, MetricNet

    private func calculateITSMSavings() -> SavingsProjection {
        // ServiceNow: Up to 60% AI ticket volume reduction
        let ticketReduction = BenchmarkData.ITSM.AutomationImpact.aiTicketVolumeReduction

        // Forrester: 50-60% reduction in repeated questions
        let repeatReduction = BenchmarkData.ITSM.AutomationImpact.aiRepeatedQuestionReduction
        let avgRepeatReduction = (repeatReduction.lowerBound + repeatReduction.upperBound) / 2

        let annualSavings = costBreakdown.totalCost * avgRepeatReduction
        let threeYearSavings = annualSavings * 3

        // ServiceNow: 37-52% faster ticket handling
        let speedImprovement = BenchmarkData.ITSM.AutomationImpact.ticketHandlingSpeed
        let avgSpeedImprovement = (speedImprovement.lowerBound + speedImprovement.upperBound) / 2
        let hoursRecovered = costBreakdown.annualHours * avgSpeedImprovement

        let roi = BenchmarkData.AutomationAnywhere.roiThreeYear
        let paybackMonths = BenchmarkData.AutomationAnywhere.paybackMonths

        return SavingsProjection(
            annualSavings: annualSavings,
            threeYearSavings: threeYearSavings,
            hoursRecovered: hoursRecovered,
            roi: roi,
            paybackMonths: paybackMonths,
            department: .itsm,
            primaryBenefit: "Up to 60% ticket volume reduction via AI",
            primarySource: "ServiceNow, Forrester, MetricNet",
            keyBenefits: [
                BenefitItem(
                    icon: "ticket.fill",
                    headline: "\(Int(ticketReduction * 100))%",
                    description: "Ticket volume reduction",
                    source: "ServiceNow"
                ),
                BenefitItem(
                    icon: "gauge.with.needle.fill",
                    headline: "\(Int(avgSpeedImprovement * 100))%",
                    description: "Faster ticket handling",
                    source: "ServiceNow"
                ),
                BenefitItem(
                    icon: "arrow.down.circle.fill",
                    headline: "\(Int(avgRepeatReduction * 100))%",
                    description: "Fewer repeated questions",
                    source: "Forrester"
                )
            ],
            forresterData: createForresterData()
        )
    }

    // MARK: - Forrester TEI Data
    /// This data is constant across all departments - from the Forrester TEI Study

    private func createForresterData() -> ForresterTEIData {
        return ForresterTEIData(
            roi: BenchmarkData.AutomationAnywhere.roiThreeYear,
            paybackMonths: BenchmarkData.AutomationAnywhere.paybackMonths,
            totalBenefitsThreeYear: BenchmarkData.AutomationAnywhere.totalBenefitsThreeYear,
            staffRedeploymentSavings: BenchmarkData.AutomationAnywhere.staffRedeploymentSavings,
            complianceAuditSavings: BenchmarkData.AutomationAnywhere.complianceAuditSavings,
            errorReductionSavings: BenchmarkData.AutomationAnywhere.errorReductionSavings,
            source: BenchmarkData.AutomationAnywhere.source,
            sourceURL: BenchmarkData.AutomationAnywhere.sourceURL
        )
    }
}

// MARK: - Savings Projection Result

struct SavingsProjection {
    let annualSavings: Double
    let threeYearSavings: Double
    let hoursRecovered: Double
    let roi: Double
    let paybackMonths: Int
    let department: Department
    let primaryBenefit: String
    let primarySource: String
    let keyBenefits: [BenefitItem]
    let forresterData: ForresterTEIData

    /// Formatted annual savings
    var formattedAnnualSavings: String {
        annualSavings.formattedAsCurrency
    }

    /// Formatted three-year savings
    var formattedThreeYearSavings: String {
        threeYearSavings.formattedAsCurrency
    }

    /// Formatted hours recovered
    var formattedHoursRecovered: String {
        Int(hoursRecovered).formattedWithCommas
    }

    /// ROI as formatted percentage
    var formattedROI: String {
        "\(Int(roi * 100))%"
    }

    /// FTE equivalent of hours recovered (assuming 2080 hours/year)
    var fteEquivalent: Double {
        hoursRecovered / 2080
    }

    /// Formatted FTE equivalent
    var formattedFTEEquivalent: String {
        if fteEquivalent < 1 {
            return String(format: "%.1f", fteEquivalent)
        } else {
            return "\(Int(fteEquivalent))"
        }
    }
}

// MARK: - Benefit Item

struct BenefitItem: Identifiable {
    let id = UUID()
    let icon: String
    let headline: String
    let description: String
    let source: String
}

// MARK: - Forrester TEI Data

struct ForresterTEIData {
    let roi: Double
    let paybackMonths: Int
    let totalBenefitsThreeYear: Double
    let staffRedeploymentSavings: Double
    let complianceAuditSavings: Double
    let errorReductionSavings: Double
    let source: String
    let sourceURL: String

    /// Formatted ROI
    var formattedROI: String {
        "\(Int(roi * 100))%"
    }

    /// Display payback period
    var paybackDescription: String {
        paybackMonths < 12 ? "< 12 months" : "\(paybackMonths) months"
    }

    /// Formatted total benefits
    var formattedTotalBenefits: String {
        totalBenefitsThreeYear.formattedAsCurrency
    }
}

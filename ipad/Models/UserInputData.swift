import Foundation

// MARK: - User Input Data Model
/// User input data for cost calculation
/// Implements Neeti's feedback: customersServed x avgCustomerOrgSize for IT/Support calculations

struct UserInputData {

    // =========================================================================
    // CORE INPUTS (Required for ALL departments)
    // =========================================================================

    /// Company name (optional, for personalization)
    var companyName: String = ""

    /// Number of employees in user's organization
    var employeeCount: Int = 1_000

    /// Number of customers the user serves/supports (for IT/Support calculations)
    var customersServed: Int = 100

    /// Average size (number of employees) of customer organizations
    var avgCustomerOrgSize: Int = 500

    /// Selected department
    var department: Department = .p2p

    // =========================================================================
    // DEPARTMENT-SPECIFIC INPUTS
    // =========================================================================

    var p2pData: P2PInput = P2PInput()
    var o2cData: O2CInput = O2CInput()
    var customerSupportData: CustomerSupportInput = CustomerSupportInput()
    var itsmData: ITSMInput = ITSMInput()

    // =========================================================================
    // RATE DATA
    // =========================================================================

    /// Loaded cost per hour (default $75)
    var averageHourlyRate: Double = 75.0

    /// Overhead/indirect cost multiplier (default 2.5x)
    var overheadMultiplier: Double = 2.5

    // =========================================================================
    // COMPUTED: Total Customer Employee Base
    // =========================================================================

    /// For IT/Support calculations: total employees across all customers
    /// Formula: customersServed x avgCustomerOrgSize
    var totalCustomerEmployees: Int {
        return customersServed * avgCustomerOrgSize
    }

    /// Display name for company - returns entered name or fallback
    var displayCompanyName: String {
        let trimmed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Your Organization" : trimmed
    }

    /// Short version for tight spaces - truncates if too long
    var shortCompanyName: String {
        let name = displayCompanyName
        if name.count > 20 {
            return String(name.prefix(17)) + "..."
        }
        return name
    }

    /// Whether user entered a custom company name
    var hasCustomCompanyName: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - P2P-Specific Inputs

struct P2PInput {
    /// Number of invoices processed per month
    var invoicesPerMonth: Int = 5_000

    /// Current automation level
    var currentAutomationLevel: AutomationLevel = .manual

    /// Number of AP team FTEs
    var fteCount: Int = 10

    /// Preset options for invoices per month
    static let invoicePresets: [Int] = [1_000, 5_000, 10_000, 25_000, 50_000]

    /// Preset options for team size
    static let ftePresets: [Int] = [2, 5, 10, 20, 50]
}

// MARK: - O2C-Specific Inputs

struct O2CInput {
    /// Number of orders processed per month
    var ordersPerMonth: Int = 10_000

    /// Current Days Sales Outstanding
    var currentDSO: Int = 55

    /// Number of AR team FTEs
    var fteCount: Int = 15

    /// Preset options for orders per month
    static let orderPresets: [Int] = [1_000, 5_000, 10_000, 25_000, 100_000]

    /// Preset options for DSO
    static let dsoPresets: [Int] = [25, 35, 45, 55, 70]

    /// Inferred automation level based on DSO
    var inferredAutomationLevel: AutomationLevel {
        if currentDSO > 55 { return .manual }
        if currentDSO > 40 { return .partial }
        if currentDSO > 28 { return .high }
        return .aiAugmented
    }
}

// MARK: - Customer Support Inputs
// Uses: customersServed x avgCustomerOrgSize x costPerEmployee

struct CustomerSupportInput {
    /// Cost per employee served (benchmark: varies by channel)
    /// Default: $22 (HDI North America average)
    var costPerEmployeeServed: Double = 22.0

    /// Current primary support channel
    var currentChannel: SupportChannel = .phone

    /// Number of support agents
    var agentCount: Int = 50

    /// Estimated tickets per employee per year (industry benchmark: ~0.5)
    var ticketsPerEmployeePerYear: Double = 0.5

    /// Preset options for agent count
    static let agentPresets: [Int] = [10, 25, 50, 100, 250]

    /// Inferred automation level based on channel
    var inferredAutomationLevel: AutomationLevel {
        switch currentChannel {
        case .phone, .email: return .manual
        case .chat: return .partial
        case .selfService: return .high
        case .aiAssisted: return .aiAugmented
        }
    }
}

// MARK: - ITSM Inputs
// Uses: customersServed x avgCustomerOrgSize x costPerEmployee

struct ITSMInput {
    /// Cost per employee supported (benchmark: $22 Tier-1, $104 Tier-3)
    /// Default: $22 (MetricNet Tier-1 benchmark)
    var costPerEmployeeSupported: Double = 22.0

    /// Number of IT support staff
    var itStaffCount: Int = 25

    /// Estimated password resets per month
    var passwordResetsPerMonth: Int = 1_000

    /// Estimated incidents per employee per year (industry benchmark: ~2)
    var incidentsPerEmployeePerYear: Double = 2.0

    /// Preset options for IT staff count
    static let staffPresets: [Int] = [5, 10, 25, 50, 100]

    /// Preset options for password resets
    static let passwordResetPresets: [Int] = [500, 1_000, 2_500, 5_000, 10_000]

    /// Inferred automation level based on ratio of incidents to staff
    func inferredAutomationLevel(totalEmployees: Int) -> AutomationLevel {
        let estimatedAnnualIncidents = Double(totalEmployees) * incidentsPerEmployeePerYear
        let incidentsPerStaffPerMonth = estimatedAnnualIncidents / (Double(itStaffCount) * 12)

        if incidentsPerStaffPerMonth < 160 { return .manual }
        if incidentsPerStaffPerMonth < 220 { return .partial }
        if incidentsPerStaffPerMonth < 380 { return .high }
        return .aiAugmented
    }
}

// MARK: - Input Presets

/// Common presets for core inputs
struct InputPresets {
    /// Employee count presets
    static let employeeCount: [Int] = [100, 500, 1_000, 5_000, 10_000]

    /// Customers served presets
    static let customersServed: [Int] = [10, 50, 100, 500, 1_000]

    /// Average customer org size presets
    static let avgCustomerOrgSize: [Int] = [100, 500, 1_000, 5_000, 10_000]

    /// Hourly rate presets
    static let hourlyRate: [Double] = [50, 75, 100, 150, 200]
}

// MARK: - Validation

extension UserInputData {
    /// Validate that required inputs are set
    var isValid: Bool {
        switch department {
        case .p2p:
            return p2pData.invoicesPerMonth > 0 && p2pData.fteCount > 0
        case .o2c:
            return o2cData.ordersPerMonth > 0 && o2cData.fteCount > 0
        case .customerSupport:
            return customersServed > 0 && avgCustomerOrgSize > 0
        case .itsm:
            return customersServed > 0 && avgCustomerOrgSize > 0
        }
    }

    /// Get department-specific input as string summary
    var inputSummary: String {
        switch department {
        case .p2p:
            return "\(p2pData.invoicesPerMonth.formattedWithCommas) invoices/month, \(p2pData.fteCount) FTEs"
        case .o2c:
            return "\(o2cData.ordersPerMonth.formattedWithCommas) orders/month, \(o2cData.currentDSO) days DSO"
        case .customerSupport:
            return "\(customersServed.formattedWithCommas) customers x \(avgCustomerOrgSize.formattedWithCommas) avg size"
        case .itsm:
            return "\(customersServed.formattedWithCommas) customers x \(avgCustomerOrgSize.formattedWithCommas) avg size"
        }
    }
}

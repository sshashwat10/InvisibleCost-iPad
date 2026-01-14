import SwiftUI

// MARK: - Department Input View
/// Department-specific input forms for cost calculation
/// Implements Neeti's formula: customersServed x avgCustomerOrgSize for IT/Support

struct DepartmentInputView: View {
    @Bindable var viewModel: ExperienceViewModel
    let narrationFinished: Bool
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showContinueButton = false

    private var department: Department? { viewModel.selectedDepartment }
    private var theme: DepartmentTheme { department?.theme ?? Department.p2p.theme }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background
                backgroundView(time: time)

                // Content - no scrolling, fit on screen
                VStack(spacing: 20) {
                    // Title
                    titleSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Input form based on department
                    inputFormSection(time: time)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)

                    Spacer()

                    // Continue button
                    if showContinueButton && narrationFinished {
                        continueButton
                            .transition(.opacity.combined(with: .offset(y: 20)))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    showContent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showContinueButton = true
                    }
                }
            }
        }
    }

    // MARK: - Background

    private func backgroundView(time: Double) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Animated gradient orbs with department color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.primary.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 700, height: 700)
                .offset(x: sin(time * 0.2) * 80, y: cos(time * 0.15) * 40 - 50)
                .blur(radius: 80)

            // Floating particles
            Canvas { context, size in
                for i in 0..<40 {
                    let seed = Double(i) * 1.618
                    let x = (sin(time * 0.15 + seed * 2) * 0.5 + 0.5) * size.width
                    let y = (cos(time * 0.1 + seed * 1.5) * 0.5 + 0.5) * size.height
                    let pulse = sin(time * 1.5 + seed) * 0.5 + 0.5
                    let particleSize: CGFloat = 1.5 + CGFloat(pulse) * 2

                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                        with: .color(theme.primary.opacity(0.06 + pulse * 0.06))
                    )
                }
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("YOUR \(department?.displayName ?? "PROCESS")")
                .font(.system(size: 14, design: .rounded).weight(.medium))
                .tracking(8)
                .foregroundColor(theme.accent)

            Text("Tell us about your organization")
                .font(.system(size: 32, design: .rounded).weight(.ultraLight))
                .foregroundColor(.white)
        }
    }

    // MARK: - Input Form Section

    @ViewBuilder
    private func inputFormSection(time: Double) -> some View {
        switch department {
        case .p2p:
            P2PInputForm(viewModel: viewModel, theme: theme, narrationFinished: narrationFinished, time: time)
        case .o2c:
            O2CInputForm(viewModel: viewModel, theme: theme, narrationFinished: narrationFinished, time: time)
        case .customerSupport:
            CustomerSupportInputForm(viewModel: viewModel, theme: theme, narrationFinished: narrationFinished, time: time)
        case .itsm:
            ITSMInputForm(viewModel: viewModel, theme: theme, narrationFinished: narrationFinished, time: time)
        case .none:
            EmptyView()
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onContinue()
        }) {
            HStack(spacing: 12) {
                Text("Calculate My Cost")
                    .font(.system(size: 17, design: .rounded).weight(.medium))

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: theme.primary.opacity(0.4), radius: 15)
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }
}

// MARK: - P2P Input Form

struct P2PInputForm: View {
    @Bindable var viewModel: ExperienceViewModel
    let theme: DepartmentTheme
    let narrationFinished: Bool
    let time: Double

    var body: some View {
        VStack(spacing: 16) {
            // Company name
            InputFieldCompact(
                label: "COMPANY NAME (OPTIONAL)",
                theme: theme,
                isEnabled: narrationFinished
            ) {
                TextField("", text: $viewModel.userInput.companyName, prompt: Text("Your Company").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 15, design: .rounded).weight(.light))
                    .foregroundColor(.white)
                    .disabled(!narrationFinished)
            }

            // Invoices per month
            InputFieldCompact(
                label: "INVOICES PER MONTH",
                theme: theme,
                isEnabled: narrationFinished
            ) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.p2pData.invoicesPerMonth,
                    presets: P2PInput.invoicePresets,
                    formatter: { "\($0.formattedWithCommas)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            // AP Team Size
            InputFieldCompact(
                label: "AP TEAM SIZE (FTEs)",
                theme: theme,
                isEnabled: narrationFinished
            ) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.p2pData.fteCount,
                    presets: P2PInput.ftePresets,
                    formatter: { "\($0)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            // Automation level
            InputFieldCompact(
                label: "CURRENT AUTOMATION",
                theme: theme,
                isEnabled: narrationFinished
            ) {
                Picker("", selection: $viewModel.userInput.p2pData.currentAutomationLevel) {
                    ForEach(AutomationLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!narrationFinished)
            }

            // Live cost preview
            costPreviewCompact(time: time)
        }
        .padding(24)
        .background(inputCardBackground)
        .frame(maxWidth: 550)
    }

    private func costPreviewCompact(time: Double) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, theme.primary.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.bottom, 4)

            Text("ESTIMATED INVISIBLE COST")
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))

            ZStack {
                Text(viewModel.costBreakdownResult.formattedTotalCost)
                    .font(.system(size: 32, design: .rounded).weight(.light))
                    .foregroundColor(theme.primary.opacity(0.3))
                    .blur(radius: 10)

                Text(viewModel.costBreakdownResult.formattedTotalCost)
                    .font(.system(size: 32, design: .rounded).weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent, theme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: theme.primary.opacity(0.5), radius: 10)
                    .contentTransition(.numericText())
            }
            .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.02)

            Text("per year")
                .font(.system(size: 11, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var inputCardBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(.ultraThinMaterial.opacity(0.3))
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.3), .white.opacity(0.1), theme.primary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

// MARK: - O2C Input Form

struct O2CInputForm: View {
    @Bindable var viewModel: ExperienceViewModel
    let theme: DepartmentTheme
    let narrationFinished: Bool
    let time: Double

    var body: some View {
        VStack(spacing: 16) {
            InputFieldCompact(label: "COMPANY NAME (OPTIONAL)", theme: theme, isEnabled: narrationFinished) {
                TextField("", text: $viewModel.userInput.companyName, prompt: Text("Your Company").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 15, design: .rounded).weight(.light))
                    .foregroundColor(.white)
                    .disabled(!narrationFinished)
            }

            InputFieldCompact(label: "ORDERS PER MONTH", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.o2cData.ordersPerMonth,
                    presets: O2CInput.orderPresets,
                    formatter: { "\($0.formattedWithCommas)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            InputFieldCompact(label: "CURRENT DSO (DAYS)", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.o2cData.currentDSO,
                    presets: O2CInput.dsoPresets,
                    formatter: { "\($0)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            InputFieldCompact(label: "AR TEAM SIZE (FTEs)", theme: theme, isEnabled: narrationFinished) {
                HStack {
                    Slider(value: Binding(
                        get: { Double(viewModel.userInput.o2cData.fteCount) },
                        set: { viewModel.userInput.o2cData.fteCount = Int($0) }
                    ), in: 1...100, step: 1)
                    .tint(theme.accent)
                    .disabled(!narrationFinished)

                    Text("\(viewModel.userInput.o2cData.fteCount)")
                        .font(.system(size: 15, design: .rounded).weight(.medium))
                        .foregroundColor(theme.accent)
                        .frame(width: 35)
                }
            }

            costPreviewCompact(time: time)
        }
        .padding(24)
        .background(inputCardBackground)
        .frame(maxWidth: 550)
    }

    private func costPreviewCompact(time: Double) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, theme.primary.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.bottom, 4)

            Text("ESTIMATED INVISIBLE COST")
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))

            Text(viewModel.costBreakdownResult.formattedTotalCost)
                .font(.system(size: 32, design: .rounded).weight(.light))
                .foregroundStyle(LinearGradient(colors: [theme.accent, theme.primary], startPoint: .leading, endPoint: .trailing))
                .shadow(color: theme.primary.opacity(0.5), radius: 10)
                .contentTransition(.numericText())
                .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.02)

            Text("per year")
                .font(.system(size: 11, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var inputCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial.opacity(0.3))
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.02)))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [theme.primary.opacity(0.3), .white.opacity(0.1), theme.primary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
    }
}

// MARK: - Customer Support Input Form
// Uses: customersServed x avgCustomerOrgSize formula

struct CustomerSupportInputForm: View {
    @Bindable var viewModel: ExperienceViewModel
    let theme: DepartmentTheme
    let narrationFinished: Bool
    let time: Double

    var body: some View {
        VStack(spacing: 14) {
            InputFieldCompact(label: "COMPANY NAME (OPTIONAL)", theme: theme, isEnabled: narrationFinished) {
                TextField("", text: $viewModel.userInput.companyName, prompt: Text("Your Company").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 15, design: .rounded).weight(.light))
                    .foregroundColor(.white)
                    .disabled(!narrationFinished)
            }

            InputFieldCompact(label: "CUSTOMERS SERVED", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.customersServed,
                    presets: InputPresets.customersServed,
                    formatter: { "\($0.formattedWithCommas)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            InputFieldCompact(label: "AVG CUSTOMER ORG SIZE", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.avgCustomerOrgSize,
                    presets: InputPresets.avgCustomerOrgSize,
                    formatter: { "\($0.formattedWithCommas)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            // Support channel picker - custom buttons for reliable tap handling
            VStack(alignment: .leading, spacing: 4) {
                Text("PRIMARY SUPPORT CHANNEL")
                    .font(.system(size: 9, design: .rounded).weight(.medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(narrationFinished ? 0.4 : 0.2))

                HStack(spacing: 0) {
                    ForEach(SupportChannel.allCases, id: \.self) { channel in
                        Button(action: {
                            if narrationFinished {
                                viewModel.userInput.customerSupportData.currentChannel = channel
                            }
                        }) {
                            Text(channel.displayName)
                                .font(.system(size: 11, design: .rounded).weight(.medium))
                                .foregroundColor(viewModel.userInput.customerSupportData.currentChannel == channel ? .black : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.userInput.customerSupportData.currentChannel == channel
                                        ? Color.white.opacity(0.9)
                                        : Color.white.opacity(0.1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!narrationFinished)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .opacity(narrationFinished ? 1.0 : 0.5)
            .animation(.easeOut(duration: 0.3), value: narrationFinished)

            formulaDisplayCompact
            costPreviewCompact(time: time)
        }
        .padding(24)
        .background(inputCardBackground)
        .frame(maxWidth: 550)
    }

    private var formulaDisplayCompact: some View {
        HStack(spacing: 8) {
            VStack(spacing: 1) {
                Text("\(viewModel.userInput.customersServed.formattedWithCommas)")
                    .font(.system(size: 14, design: .rounded).weight(.medium))
                    .foregroundColor(theme.accent)
                Text("customers")
                    .font(.system(size: 8, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("x").font(.system(size: 12)).foregroundColor(.white.opacity(0.3))
            VStack(spacing: 1) {
                Text("\(viewModel.userInput.avgCustomerOrgSize.formattedWithCommas)")
                    .font(.system(size: 14, design: .rounded).weight(.medium))
                    .foregroundColor(theme.accent)
                Text("avg size")
                    .font(.system(size: 8, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("=").font(.system(size: 12)).foregroundColor(.white.opacity(0.3))
            VStack(spacing: 1) {
                Text("\(viewModel.userInput.totalCustomerEmployees.formattedWithCommas)")
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                Text("supported")
                    .font(.system(size: 8, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.glow.opacity(0.1)))
    }

    private func costPreviewCompact(time: Double) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, theme.primary.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
            Text("ESTIMATED INVISIBLE COST")
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
            Text(viewModel.costBreakdownResult.formattedTotalCost)
                .font(.system(size: 32, design: .rounded).weight(.light))
                .foregroundStyle(LinearGradient(colors: [theme.accent, theme.primary], startPoint: .leading, endPoint: .trailing))
                .shadow(color: theme.primary.opacity(0.5), radius: 10)
                .contentTransition(.numericText())
                .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.02)
            Text("per year")
                .font(.system(size: 11, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var inputCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial.opacity(0.3))
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.02)))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [theme.primary.opacity(0.3), .white.opacity(0.1), theme.primary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
    }
}

// MARK: - ITSM Input Form
// Uses: customersServed x avgCustomerOrgSize formula

struct ITSMInputForm: View {
    @Bindable var viewModel: ExperienceViewModel
    let theme: DepartmentTheme
    let narrationFinished: Bool
    let time: Double

    var body: some View {
        VStack(spacing: 14) {
            InputFieldCompact(label: "COMPANY NAME (OPTIONAL)", theme: theme, isEnabled: narrationFinished) {
                TextField("", text: $viewModel.userInput.companyName, prompt: Text("Your Company").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 15, design: .rounded).weight(.light))
                    .foregroundColor(.white)
                    .disabled(!narrationFinished)
            }

            InputFieldCompact(label: "CUSTOMERS SERVED", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.customersServed,
                    presets: InputPresets.customersServed,
                    formatter: { "\($0.formattedWithCommas)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            InputFieldCompact(label: "AVG CUSTOMER ORG SIZE", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.avgCustomerOrgSize,
                    presets: InputPresets.avgCustomerOrgSize,
                    formatter: { "\($0.formattedWithCommas)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            InputFieldCompact(label: "IT SUPPORT STAFF", theme: theme, isEnabled: narrationFinished) {
                PresetSelectorCompact(
                    value: $viewModel.userInput.itsmData.itStaffCount,
                    presets: ITSMInput.staffPresets,
                    formatter: { "\($0)" },
                    theme: theme,
                    isEnabled: narrationFinished
                )
            }

            formulaDisplayCompact
            costPreviewCompact(time: time)
        }
        .padding(24)
        .background(inputCardBackground)
        .frame(maxWidth: 550)
    }

    private var formulaDisplayCompact: some View {
        HStack(spacing: 8) {
            VStack(spacing: 1) {
                Text("\(viewModel.userInput.customersServed.formattedWithCommas)")
                    .font(.system(size: 14, design: .rounded).weight(.medium))
                    .foregroundColor(theme.accent)
                Text("customers")
                    .font(.system(size: 8, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("x").font(.system(size: 12)).foregroundColor(.white.opacity(0.3))
            VStack(spacing: 1) {
                Text("\(viewModel.userInput.avgCustomerOrgSize.formattedWithCommas)")
                    .font(.system(size: 14, design: .rounded).weight(.medium))
                    .foregroundColor(theme.accent)
                Text("avg size")
                    .font(.system(size: 8, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("=").font(.system(size: 12)).foregroundColor(.white.opacity(0.3))
            VStack(spacing: 1) {
                Text("\(viewModel.userInput.totalCustomerEmployees.formattedWithCommas)")
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                Text("supported")
                    .font(.system(size: 8, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.glow.opacity(0.1)))
    }

    private func costPreviewCompact(time: Double) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, theme.primary.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
            Text("ESTIMATED INVISIBLE COST")
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
            Text(viewModel.costBreakdownResult.formattedTotalCost)
                .font(.system(size: 32, design: .rounded).weight(.light))
                .foregroundStyle(LinearGradient(colors: [theme.accent, theme.primary], startPoint: .leading, endPoint: .trailing))
                .shadow(color: theme.primary.opacity(0.5), radius: 10)
                .contentTransition(.numericText())
                .scaleEffect(1.0 + CGFloat(sin(time * 2)) * 0.02)
            Text("per year")
                .font(.system(size: 11, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var inputCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial.opacity(0.3))
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.02)))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [theme.primary.opacity(0.3), .white.opacity(0.1), theme.primary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
    }
}

// MARK: - Shared Components

struct InputField<Content: View>: View {
    let label: String
    let theme: DepartmentTheme
    let isEnabled: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, design: .rounded).weight(.medium))
                .tracking(3)
                .foregroundColor(.white.opacity(isEnabled ? 0.4 : 0.2))

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isEnabled ? 0.05 : 0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(isEnabled ? 0.1 : 0.05), lineWidth: 1)
                        )
                )
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.easeOut(duration: 0.3), value: isEnabled)
    }
}

struct PresetSelector<T: Hashable>: View {
    @Binding var value: T
    let presets: [T]
    let formatter: (T) -> String
    let theme: DepartmentTheme
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(presets, id: \.self) { preset in
                Button(action: {
                    guard isEnabled else { return }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    value = preset
                }) {
                    Text(formatter(preset))
                        .font(.system(size: 15, design: .rounded).weight(value == preset ? .medium : .light))
                        .foregroundColor(value == preset ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(value == preset ? theme.accent : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(value == preset ? theme.accent : Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            }
        }
    }
}

// MARK: - Compact Components

struct InputFieldCompact<Content: View>: View {
    let label: String
    let theme: DepartmentTheme
    let isEnabled: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, design: .rounded).weight(.medium))
                .tracking(2)
                .foregroundColor(.white.opacity(isEnabled ? 0.4 : 0.2))

            content
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(isEnabled ? 0.05 : 0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(isEnabled ? 0.1 : 0.05), lineWidth: 1)
                        )
                )
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.easeOut(duration: 0.3), value: isEnabled)
    }
}

struct PresetSelectorCompact<T: Hashable>: View {
    @Binding var value: T
    let presets: [T]
    let formatter: (T) -> String
    let theme: DepartmentTheme
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                Button(action: {
                    guard isEnabled else { return }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    value = preset
                }) {
                    Text(formatter(preset))
                        .font(.system(size: 12, design: .rounded).weight(value == preset ? .medium : .light))
                        .foregroundColor(value == preset ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(value == preset ? theme.accent : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(value == preset ? theme.accent : Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ExperienceViewModel()
    viewModel.selectedDepartment = .p2p
    return DepartmentInputView(
        viewModel: viewModel,
        narrationFinished: true,
        onContinue: { }
    )
}

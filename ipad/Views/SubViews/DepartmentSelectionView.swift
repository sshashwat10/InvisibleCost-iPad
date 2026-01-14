import SwiftUI

// MARK: - Department Selection View
/// 4-card selection for enterprise process departments
/// P2P, O2C, Customer Support, ITSM
/// Implements Neeti's feedback: process-focused selection

struct DepartmentSelectionView: View {
    @Binding var selectedDepartment: Department?
    let onSelection: (Department) -> Void
    let narrationFinished: Bool

    @State private var showContent = false
    @State private var hoveredDepartment: Department?

    // Colors
    private let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.04)
    private let warmGold = Color(red: 0.95, green: 0.8, blue: 0.4)

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Background
                backgroundLayer(time: time)

                // Content
                VStack(spacing: 40) {
                    // Title
                    titleSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Department cards - 2x2 grid
                    departmentGrid(time: time)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                }
                .padding(.horizontal, 60)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Background

    private func backgroundLayer(time: Double) -> some View {
        ZStack {
            voidBlack.ignoresSafeArea()

            // Animated gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [warmGold.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 800, height: 800)
                .offset(x: sin(time * 0.15) * 60, y: cos(time * 0.12) * 30 - 100)
                .blur(radius: 100)

            // Floating particles
            Canvas { context, size in
                for i in 0..<30 {
                    let seed = Double(i) * 1.618
                    let x = (sin(time * 0.12 + seed * 2) * 0.5 + 0.5) * size.width
                    let y = (cos(time * 0.08 + seed * 1.5) * 0.5 + 0.5) * size.height
                    let pulse = sin(time * 1.5 + seed) * 0.5 + 0.5
                    let particleSize: CGFloat = 1.5 + CGFloat(pulse) * 2

                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                        with: .color(warmGold.opacity(0.05 + pulse * 0.05))
                    )
                }
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("SELECT YOUR PROCESS")
                .font(.system(size: 14, design: .rounded).weight(.medium))
                .tracking(8)
                .foregroundColor(warmGold)

            Text("Where does your invisible cost hide?")
                .font(.system(size: 32, design: .rounded).weight(.ultraLight))
                .foregroundColor(.white)
        }
    }

    // MARK: - Department Grid

    private func departmentGrid(time: Double) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 24),
            GridItem(.flexible(), spacing: 24)
        ], spacing: 24) {
            ForEach(Department.allCases) { department in
                DepartmentCard(
                    department: department,
                    isSelected: selectedDepartment == department,
                    isHovered: hoveredDepartment == department,
                    isEnabled: narrationFinished,
                    time: time
                )
                .onTapGesture {
                    guard narrationFinished else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedDepartment = department
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onSelection(department)
                }
                .onHover { isHovered in
                    withAnimation(.easeOut(duration: 0.2)) {
                        hoveredDepartment = isHovered ? department : nil
                    }
                }
            }
        }
        .frame(maxWidth: 800)
    }
}

// MARK: - Department Card

struct DepartmentCard: View {
    let department: Department
    let isSelected: Bool
    let isHovered: Bool
    let isEnabled: Bool
    let time: Double

    private var theme: DepartmentTheme { department.theme }

    var body: some View {
        VStack(spacing: 20) {
            // Icon with animated glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.primary.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.0 + sin(time * 1.5) * 0.08)
                    .blur(radius: 8)

                // Inner ring
                Circle()
                    .stroke(theme.accent.opacity(0.5), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.0 + sin(time * 2) * 0.05)

                // Icon
                Image(systemName: department.icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent, theme.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: theme.accent.opacity(0.6), radius: 10)
            }

            // Department name
            Text(department.displayName)
                .font(.system(size: 14, design: .rounded).weight(.semibold))
                .tracking(4)
                .foregroundColor(isEnabled ? theme.accent : theme.accent.opacity(0.5))

            // Key process
            Text(department.keyProcess)
                .font(.system(size: 16, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(isEnabled ? 0.9 : 0.5))

            // Pain description
            Text(department.painDescription)
                .font(.system(size: 12, design: .rounded).weight(.light))
                .foregroundColor(.white.opacity(isEnabled ? 0.5 : 0.3))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 36)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isSelected ? theme.accent : theme.cardBorder,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : (isHovered ? 1.01 : 1.0))
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - Legacy Compatibility Alias

/// For backward compatibility with existing NarrativeView
struct IndustrySelectionView: View {
    @Binding var selectedIndustry: Department?
    let onSelection: (Department) -> Void
    let narrationFinished: Bool

    var body: some View {
        DepartmentSelectionView(
            selectedDepartment: $selectedIndustry,
            onSelection: onSelection,
            narrationFinished: narrationFinished
        )
    }
}

// MARK: - Preview

#Preview {
    DepartmentSelectionView(
        selectedDepartment: .constant(nil),
        onSelection: { _ in },
        narrationFinished: true
    )
}
